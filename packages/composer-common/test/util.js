/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

'use strict';

const Connection = require('../lib/connection');
const os = require('os');
const path = require('path');
const SecurityContext = require('../lib/securitycontext');
const SecurityException = require('../lib/securityexception');
const Util = require('../lib/util');
const uuid = require('uuid');
const chai = require('chai');
const chaiAsPromised = require('chai-as-promised');
const sinon = require('sinon');
const Resource = require('../lib/model/resource');
const Serializer = require('../lib/serializer');
const ModelManager = require('../lib/modelmanager');
chai.use(chaiAsPromised);
chai.should();

describe('Util', function () {

    const levelOneModel = `namespace org.acme.l1
  participant Person identified by ssn {
    o String ssn
  }
  asset Car identified by vin {
    o String vin
    -->Person owner
  }
  transaction ScrapCar {
   -->Car car
  }
  `;

    let modelManager = null;
    let mockConnection;
    let mockSecurityContext;
    let sandbox;

    let mockSerializer;

    beforeEach(function () {
        sandbox = sinon.sandbox.create();
        mockConnection = sinon.createStubInstance(Connection);
        mockConnection.invokeChainCode.returns(Promise.resolve());
        mockConnection.queryChainCode.returns(Promise.resolve());
        mockConnection.createTransactionId.resolves({id:'tx1234567890',idStr:'1234567890'});
        mockSecurityContext = sinon.createStubInstance(SecurityContext);
        mockSecurityContext.getConnection.returns(mockConnection);

        mockSerializer = sinon.createStubInstance(Serializer);

        modelManager = new ModelManager();
        modelManager.addModelFile(levelOneModel);
    });

    afterEach(function () {
        sandbox.restore();
    });

    describe('#securityCheck', function () {

        it('should throw for an undefined security context', function () {
            (function () {
                Util.securityCheck(undefined);
            }).should.throw(SecurityException, 'Connection needs to be connected. Call connect(..)');
        });

        it('should throw for a null security context', function () {
            (function () {
                Util.securityCheck(null);
            }).should.throw(SecurityException, 'Connection needs to be connected. Call connect(..)');
        });

        it('should throw for an invalid type of security context', function () {
            (function () {
                Util.securityCheck([{}]);
            }).should.throw(SecurityException, 'A valid SecurityContext must be specified.');
        });

        it('should work for a valid security context', function () {
            Util.securityCheck(mockSecurityContext);
        });

    });

    describe('#submitTransaction',  function() {

        it('should process a transaction as json', function () {
            let stub = sandbox.stub(Util, 'securityCheck');
            let json =  {
                $class: 'org.acme.l1.ScrapCar',
                car: 'resource:org.acme.l1.Car#456',
                timestamp: '1970-01-01T00:00:00.000Z',
                transactionId: '789'
            };
            return Util
                .submitTransaction(mockSecurityContext,json)
                .then(() => {
                    sinon.assert.called(stub);
                    sinon.assert.called(mockConnection.invokeChainCode);
                    sinon.assert.calledWith(mockConnection.invokeChainCode,mockSecurityContext,'submitTransaction',[JSON.stringify(json)],{transactionId:'tx1234567890'});
                });
        });

        it('should process a transaction as resource', function () {
            let stub = sandbox.stub(Util, 'securityCheck');
            let json =  {
                $class: 'org.acme.l1.ScrapCar',
                car: 'resource:org.acme.l1.Car#456',
                timestamp: '1970-01-01T00:00:00.000Z',
                transactionId: '789'
            };
            const classDecl = modelManager.getType('org.acme.l1.ScrapCar');
            const resource = new Resource(modelManager, classDecl, 'org.acme.l1', 'ScrapCar', '789' );
            let setIdSpy = sinon.spy(resource,'setIdentifier');
            mockSerializer.toJSON.returns(json);
            resource.timestamp = new Date(0);
            resource.car = modelManager.getFactory().newRelationship('org.acme.l1', 'Car', '456');
            return Util
                .submitTransaction(mockSecurityContext,resource,mockSerializer)
                .then(() => {
                    sinon.assert.called(setIdSpy);
                    sinon.assert.called(stub);
                    sinon.assert.called(mockConnection.invokeChainCode);
                    sinon.assert.calledWith(mockConnection.invokeChainCode,mockSecurityContext,'submitTransaction',[JSON.stringify(json)],{transactionId:'tx1234567890'});
                });
        });

        it('should process a transaction as json and return the result', function () {
            let stub = sandbox.stub(Util, 'securityCheck');
            let json =  {
                $class: 'org.acme.l1.ScrapCar',
                car: 'resource:org.acme.l1.Car#456',
                timestamp: '1970-01-01T00:00:00.000Z',
                transactionId: '789'
            };
            mockConnection.invokeChainCode.resolves('hello world');
            return Util
                .submitTransaction(mockSecurityContext,json)
                .then((result) => {
                    result.should.equal('hello world');
                    sinon.assert.called(stub);
                    sinon.assert.called(mockConnection.invokeChainCode);
                    sinon.assert.calledWith(mockConnection.invokeChainCode,mockSecurityContext,'submitTransaction',[JSON.stringify(json)],{transactionId:'tx1234567890'});
                });
        });

        it('should process a transaction as resource and return the result', function () {
            let stub = sandbox.stub(Util, 'securityCheck');
            let json =  {
                $class: 'org.acme.l1.ScrapCar',
                car: 'resource:org.acme.l1.Car#456',
                timestamp: '1970-01-01T00:00:00.000Z',
                transactionId: '789'
            };
            const classDecl = modelManager.getType('org.acme.l1.ScrapCar');
            const resource = new Resource(modelManager, classDecl, 'org.acme.l1', 'ScrapCar', '789' );
            let setIdSpy = sinon.spy(resource,'setIdentifier');
            mockSerializer.toJSON.returns(json);
            resource.timestamp = new Date(0);
            resource.car = modelManager.getFactory().newRelationship('org.acme.l1', 'Car', '456');
            mockConnection.invokeChainCode.resolves('hello world');
            return Util
                .submitTransaction(mockSecurityContext,resource,mockSerializer)
                .then((result) => {
                    result.should.equal('hello world');
                    sinon.assert.called(setIdSpy);
                    sinon.assert.called(stub);
                    sinon.assert.called(mockConnection.invokeChainCode);
                    sinon.assert.calledWith(mockConnection.invokeChainCode,mockSecurityContext,'submitTransaction',[JSON.stringify(json)],{transactionId:'tx1234567890'});
                });
        });

    });


    describe('#queryChainCode', function () {

        it('should perform a security check', function () {
            let stub = sandbox.stub(Util, 'securityCheck');
            return Util
                .queryChainCode(mockSecurityContext, 'init', [])
                .then(() => {
                    sinon.assert.called(stub);
                });
        });

        it('should throw when functionName is not specified', function () {
            (function () {
                Util.queryChainCode(mockSecurityContext, null, []);
            }).should.throw(/functionName not specified/);
        });

        it('should throw when args is not specified', function () {
            (function () {
                Util.queryChainCode(mockSecurityContext, 'function', null);
            }).should.throw(/args not specified/);
        });

        it('should throw when args contains an invalid value', function () {
            (function () {
                Util.queryChainCode(mockSecurityContext, 'function', [undefined]);
            }).should.throw(/invalid arg specified: undefined/);
        });

        it('should query the chain-code with strings and return the result', function () {
            mockConnection.queryChainCode.resolves('hello world');
            return Util.queryChainCode(mockSecurityContext, 'function', ['arg1', 'arg2'])
                .then((result) => {
                    result.should.equal('hello world');
                    sinon.assert.calledOnce(mockConnection.queryChainCode);
                    sinon.assert.calledWith(mockConnection.queryChainCode, mockSecurityContext, 'function', ['arg1', 'arg2']);
                });
        });

        it('should query the chain-code with booleans and return the result', function () {
            mockConnection.queryChainCode.resolves('hello world');
            return Util.queryChainCode(mockSecurityContext, 'function', [true, false])
                .then((result) => {
                    result.should.equal('hello world');
                    sinon.assert.calledOnce(mockConnection.queryChainCode);
                    sinon.assert.calledWith(mockConnection.queryChainCode, mockSecurityContext, 'function', ['true', 'false']);
                });
        });

    });

    describe('#createTransactionId', function() {
        it('should perform a security check', function () {
            mockConnection.createTransactionId.resolves('42');
            let stub = sandbox.stub(Util, 'securityCheck');
            return Util
                .createTransactionId(mockSecurityContext)
                .then(() => {
                    sinon.assert.called(stub);
                });
        });

        it('call the connection to get a txid',function(){
            mockConnection.createTransactionId.resolves('42');
            return Util
                .createTransactionId(mockSecurityContext)
                .should.eventually.be.equal('42');
        });


        it('call the connection to get a txid and cope with null',function(){
            mockConnection.createTransactionId.resolves(null);
            sandbox.stub(uuid, 'v4').returns('56');
            return Util
                .createTransactionId(mockSecurityContext)
                .should.eventually.be.deep.equal({ id: '56', idStr: '56' });
        });

    });

    describe('#invokeChainCode', function () {

        it('should perform a security check', function () {
            let stub = sandbox.stub(Util, 'securityCheck');
            return Util
                .invokeChainCode(mockSecurityContext, 'init', [])
                .then(() => {
                    sinon.assert.called(stub);
                });
        });

        it('should throw when functionName is not specified', function () {
            (function () {
                Util.invokeChainCode(mockSecurityContext, null, []);
            }).should.throw(/functionName not specified/);
        });

        it('should throw when args is not specified', function () {
            (function () {
                Util.invokeChainCode(mockSecurityContext, 'function', null);
            }).should.throw(/args not specified/);
        });

        it('should throw when args contains an invalid value', function () {
            (function () {
                Util.invokeChainCode(mockSecurityContext, 'function', [undefined]);
            }).should.throw(/invalid arg specified: undefined/);
        });

        it('should invoke the chain-code', function () {
            return Util.invokeChainCode(mockSecurityContext, 'function', ['arg1', 'arg2'])
                .then(() => {
                    sinon.assert.calledOnce(mockConnection.invokeChainCode);
                    sinon.assert.calledWith(mockConnection.invokeChainCode, mockSecurityContext, 'function', ['arg1', 'arg2']);
                });
        });

        it('should invoke the chain-code and return the result', function () {
            mockConnection.invokeChainCode.resolves('hello world');
            return Util.invokeChainCode(mockSecurityContext, 'function', ['arg1', 'arg2'])
                .then((result) => {
                    result.should.equal('hello world');
                    sinon.assert.calledOnce(mockConnection.invokeChainCode);
                    sinon.assert.calledWith(mockConnection.invokeChainCode, mockSecurityContext, 'function', ['arg1', 'arg2']);
                });
        });

    });

    describe('#isNull', function () {

        it('should return true for undefined', function () {
            Util.isNull(undefined).should.equal(true);
        });

        it('should return true for null', function () {
            Util.isNull(null).should.equal(true);
        });

        it('should return false for anything else', function () {
            Util.isNull('hello').should.equal(false);
        });

    });

    describe('#homeDirectory', function() {
        it('should return valid path', function() {
            const result = Util.homeDirectory();
            path.isAbsolute(result).should.be.true;
        });

        it('should return root directory if os.homedir function returns undefined', function() {
            sandbox.stub(os, 'homedir').returns(undefined);
            const result = Util.homeDirectory();
            result.should.equal(path.sep);
        });
    });

});
