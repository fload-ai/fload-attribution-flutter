import Flutter
import UIKit
import XCTest

@testable import fload_attribution

// Unit tests of the plugin's Swift half. They never call configure, so
// nothing is sent anywhere.
class RunnerTests: XCTestCase {
  private func call(_ method: String, _ arguments: Any? = nil) -> Any? {
    let plugin = FloadAttributionPlugin()
    var answer: Any?
    let done = expectation(description: "result")
    plugin.handle(FlutterMethodCall(methodName: method, arguments: arguments)) { result in
      answer = result
      done.fulfill()
    }
    waitForExpectations(timeout: 1)
    return answer
  }

  func testOptionsDefaultToFloadsEndpointAndTheWarningLevel() {
    let options = FloadAttributionPlugin.options(endpoint: nil, logLevel: nil, wrapperName: nil, wrapperVersion: nil)
    XCTAssertEqual(options?.endpoint, URL(string: "https://ingest.fload.com"))
    XCTAssertEqual(options?.logLevel, .warning)
  }

  func testOptionsCarryTheEndpointAndLevelTheAppGives() {
    let options = FloadAttributionPlugin.options(
      endpoint: "http://localhost:3999", logLevel: "debug", wrapperName: nil, wrapperVersion: nil)
    XCTAssertEqual(options?.endpoint, URL(string: "http://localhost:3999"))
    XCTAssertEqual(options?.logLevel, .debug)
  }

  func testAnEndpointThatIsNotAURLIsRefused() {
    XCTAssertNil(FloadAttributionPlugin.options(
      endpoint: "not a url", logLevel: nil, wrapperName: "flutter", wrapperVersion: "1.1.0"))
  }

  func testOptionsNameTheWrapperAndTheVersionDartSends() {
    let options = FloadAttributionPlugin.options(
      endpoint: nil, logLevel: "debug", wrapperName: "flutter", wrapperVersion: "1.1.0")
    XCTAssertEqual(options?.wrapper, FloadWrapper(name: "flutter", version: "1.1.0"))
    XCTAssertEqual(options?.endpoint, URL(string: "https://ingest.fload.com"))
    XCTAssertEqual(options?.logLevel, .debug)
  }

  func testOptionsWithAnEndpointNameTheWrapperToo() {
    let options = FloadAttributionPlugin.options(
      endpoint: "http://localhost:3999", logLevel: nil, wrapperName: "flutter", wrapperVersion: "1.1.0")
    XCTAssertEqual(options?.endpoint, URL(string: "http://localhost:3999"))
    XCTAssertEqual(options?.wrapper, FloadWrapper(name: "flutter", version: "1.1.0"))
  }

  func testOptionsWithoutAWrapperNameOrVersionNameNone() {
    XCTAssertNil(FloadAttributionPlugin.options(endpoint: nil, logLevel: nil, wrapperName: nil, wrapperVersion: nil)?.wrapper)
    XCTAssertNil(FloadAttributionPlugin.options(endpoint: nil, logLevel: nil, wrapperName: "flutter", wrapperVersion: nil)?.wrapper)
    XCTAssertNil(FloadAttributionPlugin.options(endpoint: nil, logLevel: nil, wrapperName: nil, wrapperVersion: "1.1.0")?.wrapper)
  }

  func testEveryDartLogLevelMapsToTheSdks() {
    let expected: [String: FloadLogLevel] = [
      "none": .none, "error": .error, "warning": .warning, "info": .info, "debug": .debug,
    ]
    for (name, level) in expected {
      XCTAssertEqual(FloadAttributionPlugin.level(name), level, name)
    }
  }

  func testConfigureWithoutAKeyIsAnError() {
    let error = call("configure", ["logLevel": "debug"]) as? FlutterError
    XCTAssertEqual(error?.code, "bad_arguments")
  }

  func testAnUnknownMethodIsNotImplemented() {
    XCTAssertTrue((call("track") as AnyObject) === FlutterMethodNotImplemented)
  }
}
