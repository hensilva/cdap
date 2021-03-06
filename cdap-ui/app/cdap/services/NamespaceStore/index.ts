/*
 * Copyright © 2016 Cask Data, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not
 * use this file except in compliance with the License. You may obtain a copy of
 * the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 * License for the specific language governing permissions and limitations under
 * the License.
 */

import { combineReducers, createStore, Store as InterfaceStore } from 'redux';
import NamespaceActions from './NamespaceActions';
import { composeEnhancers, objectQuery, isNilOrEmpty } from 'services/helpers';
import { SYSTEM_NAMESPACE } from 'services/global-constants';
import { MyNamespaceApi } from 'api/namespace';
import { IAction } from 'services/redux-helpers';
import find from 'lodash/find';

export interface INamespace {
  name: string;
  description: string;
  config: any;
}

export interface INamespaceStoreState {
  username: string;
  selectedNamespace: string;
  namespaces: INamespace[];
}
const defaultAction = {
  type: '',
  payload: {} as any,
};

const defaultInitialState = {
  username: '',
  selectedNamespace: '',
  namespaces: [],
};

const username = (state = '', action: IAction = defaultAction) => {
  switch (action.type) {
    case NamespaceActions.updateUsername:
      return action.payload.username;
    default:
      return state;
  }
};

const selectedNamespace = (state = '', action: IAction = defaultAction) => {
  switch (action.type) {
    case NamespaceActions.selectNamespace: {
      if (action.payload.selectedNamespace === SYSTEM_NAMESPACE) {
        return localStorage.getItem('CurrentNamespace');
      }
      return action.payload.selectedNamespace;
    }
    case NamespaceActions.updateNamespaces: {
      const previouslyAccessedNs = localStorage.getItem('CurrentNamespace');
      if (isNilOrEmpty(state) || state === SYSTEM_NAMESPACE) {
        return !isNilOrEmpty(previouslyAccessedNs)
          ? previouslyAccessedNs
          : objectQuery(action.payload, 'namespaces', 0, 'name');
      }
      return state;
    }
    default:
      return state;
  }
};

const namespaces = (state = [], action) => {
  switch (action.type) {
    case NamespaceActions.updateNamespaces:
      return action.payload.namespaces;
    default:
      return state;
  }
};
/**
 * Store to manage namespace globally across CDAP UI.
 * Stores list of namespaces and current namespace the user is in.
 */
const NamespaceStore: InterfaceStore<INamespaceStoreState> = createStore(
  combineReducers({
    username,
    selectedNamespace,
    namespaces,
  }),
  defaultInitialState,
  composeEnhancers('NamespaceStore')()
);

const getCurrentNamespace = () => {
  const { selectedNamespace: namespace } = NamespaceStore.getState();
  return namespace;
};

const isValidNamespace = async (namespace: string) => {
  if (namespace === SYSTEM_NAMESPACE) {
    return true;
  }

  if (namespace) {
    const { namespaces: namespacesFromStore } = NamespaceStore.getState();
    let validNamespaces;
    if (namespacesFromStore.length) {
      validNamespaces = namespacesFromStore;
    } else {
      validNamespaces = await MyNamespaceApi.list().toPromise();
      NamespaceStore.dispatch({
        type: NamespaceActions.updateNamespaces,
        payload: {
          namespaces: validNamespaces,
        },
      });
    }
    const validNs = validNamespaces.find((ns: INamespace) => ns.name === namespace);
    return validNs;
  }
  return false;
};

const getValidNamespace = async (currentNs) => {
  const list = await MyNamespaceApi.list().toPromise();
  if (!list || list.length === 0) {
    throw new Error('Unable to retrieve namespaces.');
  }
  const validNs = list.find((ns: INamespace) => ns.name === currentNs);
  if (!validNs) {
    const findNamespace = (nsList, name) => {
      return find(nsList, { name });
    };

    /*
     * 1. Check if localStorage has a 'DefaultNamespace' set by the user, if not,
     * 2. Check if there is a 'default' namespace from backend, if not,
     * 3. Take first one from the list of namespaces from backend.
     */

    let selectedNs;
    let defaultNamespace;

    // Check #1
    if (!selectedNs) {
      defaultNamespace = localStorage.getItem('DefaultNamespace');
      const defaultNsFromBackend = list.filter((ns) => ns.name === defaultNamespace);
      if (defaultNsFromBackend.length) {
        selectedNs = defaultNsFromBackend[0];
      }
    }
    // Check #2
    if (!selectedNs) {
      selectedNs = findNamespace(list, 'default');
    }
    // Check #3
    if (!selectedNs) {
      selectedNs = list[0].name;
    } else {
      selectedNs = selectedNs.name;
    }

    return selectedNs;
  }
  return validNs.name;
};

export default NamespaceStore;
export { getCurrentNamespace, isValidNamespace, getValidNamespace };
