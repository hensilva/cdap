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

import React from 'react';
import { connect, Provider } from 'react-redux';
import MicroserviceUploadActions  from 'services/WizardStores/MicroserviceUpload/MicroserviceUploadActions';
import MicroserviceUploadStore from 'services/WizardStores/MicroserviceUpload/MicroserviceUploadStore';
import { Label, Form, FormGroup, Col, Input } from 'reactstrap';
import InputWithValidations from 'components/InputWithValidations';
import T from 'i18n-react';

require('./GeneralInfoStep.scss');

const mapStateToMicroserviceNameProps = (state) => {
  return {
    value: state.general.name,
    type: 'text',
    placeholder: T.translate('features.Wizard.MicroserviceUpload.Step1.namePlaceholder')
  };
};
const mapStateToMicroserviceDescritionProps = (state) => {
  return {
    value: state.general.description,
    type: 'textarea',
    rows: '7',
    placeholder: T.translate('features.Wizard.MicroserviceUpload.Step1.descriptionPlaceholder')
  };
};
const mapStateToMicroserviceVersionProps = (state) => {
  return {
    value: state.general.version,
    type: 'number',
    min: '1',
    placeholder: T.translate('features.Wizard.MicroserviceUpload.Step1.versionPlaceholder')
  };
};

const mapDispatchToMicroserviceNameProps = (dispatch) => {
  return {
    onChange: (e) => {
      dispatch({
        type: MicroserviceUploadActions.setName,
        payload: {name: e.target.value}
      });
    }
  };
};
const mapDispatchToMicroserviceDescriptionProps = (dispatch) => {
  return {
    onChange: (e) => (dispatch({
      type: MicroserviceUploadActions.setDescription,
      payload: {description: e.target.value}
    }))
  };
};
const mapDispatchToToMicroserviceVersion = (dispatch) => {
  return {
    onChange: (e) => {
      dispatch({
        type: MicroserviceUploadActions.setVersion,
        payload: {version: e.target.value}
      });
    }
  };
};

const InputMicroserviceName = connect(
  mapStateToMicroserviceNameProps,
  mapDispatchToMicroserviceNameProps
)(InputWithValidations);
const InputMicroserviceDescription = connect(
  mapStateToMicroserviceDescritionProps,
  mapDispatchToMicroserviceDescriptionProps
)(InputWithValidations);
const InputMicroserviceVersion = connect(
  mapStateToMicroserviceVersionProps,
  mapDispatchToToMicroserviceVersion
)(Input);

export default function GeneralInfoStep() {
  return (
    <Provider store={MicroserviceUploadStore}>
      <Form
        className="form-horizontal general-info-step"
        onSubmit={(e) => {
          e.preventDefault();
          return false;
        }}
      >
        <FormGroup row>
          <Col xs="3">
            <Label className="control-label">{T.translate('commons.nameLabel')}</Label>
          </Col>
          <Col xs="7">
            <InputMicroserviceName />
          </Col>
          <i className="fa fa-asterisk text-danger float-xs-left"/>
        </FormGroup>
        <FormGroup row>
          <Col xs="3">
            <Label className="control-label">{T.translate('commons.descriptionLabel')}</Label>
          </Col>
          <Col xs="7">
            <InputMicroserviceDescription />
          </Col>
        </FormGroup>
        <FormGroup row>
          <Col sm="3">
            <Label className="control-label">{T.translate('features.Wizard.MicroserviceUpload.Step1.versionLabel')} </Label>
          </Col>
          <Col sm="7">
            <InputMicroserviceVersion />
          </Col>
          <i className="fa fa-asterisk text-danger float-xs-left"/>
        </FormGroup>
      </Form>
    </Provider>
  );
}
