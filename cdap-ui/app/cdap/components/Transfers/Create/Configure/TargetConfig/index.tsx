/*
 * Copyright © 2019 Cask Data, Inc.
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

import * as React from 'react';
import PluginConfiguration from 'components/Transfers/Create/Configure/PluginConfiguration';
import { transfersCreateConnect } from 'components/Transfers/Create/context';
import { objectQuery } from 'services/helpers';

interface ITargetConfigProps {
  setTarget: (target) => void;
  target: any;
}

const TargetConfigView: React.SFC<ITargetConfigProps> = ({ setTarget, target }) => {
  const artifactName = 'delta-bigquery-plugins';
  const artifactScope = 'SYSTEM';
  const pluginName = 'bigquery';
  const pluginType = 'cdcTarget';

  const initValues = objectQuery(target, 'plugin', 'properties') || {};

  return (
    <PluginConfiguration
      onNext={setTarget}
      artifactName={artifactName}
      artifactScope={artifactScope}
      pluginType={pluginType}
      pluginName={pluginName}
      initValues={initValues}
    />
  );
};

const TargetConfig = transfersCreateConnect(TargetConfigView);
export default TargetConfig;
