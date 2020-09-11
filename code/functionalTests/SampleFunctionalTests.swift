//
// Copyright 2020 Adobe. All rights reserved.
// This file is licensed to you under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
// OF ANY KIND, either express or implied. See the License for the specific language
// governing permissions and limitations under the License.
//

import AEPCore
import AEPExperiencePlatform
import AEPIdentity
import AEPServices
import Foundation
import XCTest

/// This Test class is an example of usages of the FunctionalTestBase APIs
class SampleFunctionalTests: FunctionalTestBase {
    private let event1 = Event(name: "e1", type: "eventType", source: "eventSource", data: nil)
    private let event2 = Event(name: "e2", type: "eventType", source: "eventSource", data: nil)
    private let exEdgeInteractUrlString = "https://edge.adobedc.net/ee/v1/interact"
    private let exEdgeInteractUrl = URL(string: "https://edge.adobedc.net/ee/v1/interact")! // swiftlint:disable:this force_unwrapping
    private let responseBody = "{\"test\": \"json\"}"

    public class override func setUp() {
        super.setUp()
        FunctionalTestBase.debugEnabled = true
    }

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        // hub shared state update for 2 extension versions (InstrumentedExtension (registered in FunctionalTestBase), Identity, ExperiencePlatform), Identity and Config shared state updates
        setExpectationEvent(type: FunctionalTestConst.EventType.eventHub, source: FunctionalTestConst.EventSource.sharedState, count: 4)

        // expectations for update config request&response events
        setExpectationEvent(type: FunctionalTestConst.EventType.configuration, source: FunctionalTestConst.EventSource.requestContent, count: 1)
        setExpectationEvent(type: FunctionalTestConst.EventType.configuration, source: FunctionalTestConst.EventSource.responseContent, count: 1)

        // expectations for Identity force sync
        setExpectationEvent(type: FunctionalTestConst.EventType.identity, source: FunctionalTestConst.EventSource.requestIdentity, count: 1)
        setExpectationEvent(type: FunctionalTestConst.EventType.identity, source: FunctionalTestConst.EventSource.responseIdentity, count: 2)

        MobileCore.registerExtensions([Identity.self, ExperiencePlatform.self])
        MobileCore.updateConfigurationWith(configDict: ["global.privacy": "optedin",
                                                        "experienceCloud.org": "testOrg@AdobeOrg",
                                                        "experiencePlatform.configId": "12345-example"])

        assertExpectedEvents(ignoreUnexpectedEvents: false)
        resetTestExpectations()
    }

    // MARK: sample tests for the FunctionalTest framework usage

    func testSample_AssertUnexpectedEvents() {
        // set event expectations specifying the event type, source and the count (count should be > 0)
        setExpectationEvent(type: "eventType", source: "eventSource", count: 2)
        MobileCore.dispatch(event: event1)
        MobileCore.dispatch(event: event1)

        // assert that no unexpected event was received
        assertUnexpectedEvents()
    }

    func testSample_AssertExpectedEvents() {
        setExpectationEvent(type: "eventType", source: "eventSource", count: 2)
        MobileCore.dispatch(event: event1)
        MobileCore.dispatch(event: Event(name: "e1", type: "unexpectedType", source: "unexpectedSource", data: ["test": "withdata"]))
        MobileCore.dispatch(event: event1)

        // assert all expected events were received and ignore any unexpected events
        // when ignoreUnexpectedEvents is set on false, an extra assertUnexpectedEvents step is performed
        assertExpectedEvents(ignoreUnexpectedEvents: true)
    }

    func testSample_DispatchedEvents() {
        MobileCore.dispatch(event: event1)
        MobileCore.dispatch(event: Event(name: "e1", type: "otherEventType", source: "otherEventSource", data: ["test": "withdata"]))
        MobileCore.dispatch(event: Event(name: "e1", type: "eventType", source: "eventSource", data: ["test": "withdata"]))

        // assert on count and data for events of a certain type, source
        let dispatchedEvents = getDispatchedEventsWith(type: "eventType", source: "eventSource")

        XCTAssertEqual(2, dispatchedEvents.count)
        guard let event2data = dispatchedEvents[1].data else {
            XCTFail("Invalid event data for event 2")
            return
        }
        XCTAssertEqual(1, flattenDictionary(dict: event2data).count)
    }

    func testSample_AssertNetworkRequestsCount() {
        let responseBody = "{\"test\": \"json\"}"
        let httpConnection: HttpConnection = HttpConnection(data: responseBody.data(using: .utf8),
                                                            response: HTTPURLResponse(url: exEdgeInteractUrl,
                                                                                      statusCode: 200,
                                                                                      httpVersion: nil,
                                                                                      headerFields: nil),
                                                            error: nil)
        setExpectationNetworkRequest(url: exEdgeInteractUrlString, httpMethod: HttpMethod.post, count: 2)
        setNetworkResponseFor(url: exEdgeInteractUrlString, httpMethod: HttpMethod.post, responseHttpConnection: httpConnection)

        ExperiencePlatform.sendEvent(experiencePlatformEvent: ExperiencePlatformEvent(xdm: ["test1": "xdm"], data: nil))
        ExperiencePlatform.sendEvent(experiencePlatformEvent: ExperiencePlatformEvent(xdm: ["test2": "xdm"], data: nil))

        assertNetworkRequestsCount()
    }

    func testSample_AssertNetworkRequestAndResponseEvent() {
        setExpectationEvent(type: FunctionalTestConst.EventType.experiencePlatform, source: FunctionalTestConst.EventSource.requestContent, count: 1)
        setExpectationEvent(type: FunctionalTestConst.EventType.experiencePlatform, source: FunctionalTestConst.EventSource.responseContent, count: 1)
        // swiftlint:disable:next line_length
        let responseBody = "\u{0000}{\"requestId\":\"ded17427-c993-4182-8d94-2a169c1a23e2\",\"handle\":[{\"type\":\"identity:exchange\",\"payload\":[{\"type\":\"url\",\"id\":411,\"spec\":{\"url\":\"//cm.everesttech.net/cm/dd?d_uuid=42985602780892980519057012517360930936\",\"hideReferrer\":false,\"ttlMinutes\":10080}}]}]}\n"
        let httpConnection: HttpConnection = HttpConnection(data: responseBody.data(using: .utf8),
                                                            response: HTTPURLResponse(url: exEdgeInteractUrl,
                                                                                      statusCode: 200,
                                                                                      httpVersion: nil,
                                                                                      headerFields: nil),
                                                            error: nil)
        setExpectationNetworkRequest(url: exEdgeInteractUrlString, httpMethod: HttpMethod.post, count: 1)
        setNetworkResponseFor(url: exEdgeInteractUrlString, httpMethod: HttpMethod.post, responseHttpConnection: httpConnection)

        ExperiencePlatform.sendEvent(experiencePlatformEvent: ExperiencePlatformEvent(xdm: ["eventType": "testType", "test": "xdm"], data: nil))

        let requests = getNetworkRequestsWith(url: exEdgeInteractUrlString, httpMethod: HttpMethod.post)

        XCTAssertEqual(1, requests.count)
        let flattenRequestBody = getFlattenNetworkRequestBody(requests[0])
        XCTAssertEqual("testType", flattenRequestBody["events[0].xdm.eventType"] as? String)

        assertExpectedEvents(ignoreUnexpectedEvents: true)
    }
}
