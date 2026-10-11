import ApplicationServices
import CoreGraphics

@_silgen_name("_AXUIElementGetWindow")
nonisolated func _AXUIElementGetWindow(
  _ element: AXUIElement,
  _ windowID: UnsafeMutablePointer<CGWindowID>
) -> AXError

@_silgen_name("CGSMainConnectionID")
func CGSMainConnectionID() -> Int32

@_silgen_name("CGSManagedDisplayGetCurrentSpace")
func CGSManagedDisplayGetCurrentSpace(_ connection: Int32, _ displayUUID: CFString) -> UInt64

nonisolated let skyLightFrameworkPath =
  "/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight"
nonisolated let applicationServicesFrameworkPath =
  "/System/Library/Frameworks/ApplicationServices.framework/ApplicationServices"

typealias GetProcessForPIDFunction = @convention(c) (
  pid_t, UnsafeMutablePointer<ProcessSerialNumber>
) -> OSStatus
typealias SetFrontProcessWithOptionsFunction = @convention(c) (
  UnsafeMutablePointer<ProcessSerialNumber>, UInt32, UInt32
) -> CGError
typealias PostEventRecordFunction = @convention(c) (
  UnsafeMutablePointer<ProcessSerialNumber>, UnsafeMutablePointer<UInt8>
) -> CGError

nonisolated let multitouchFrameworkPath = "/System/Library/PrivateFrameworks/MultitouchSupport.framework/MultitouchSupport"

nonisolated struct MTTouch {
  var frame: Int32
  var timestamp: Double
  var identifier: Int32
  var state: Int32
  var fingerID: Int32
  var handID: Int32
  var positionX: Float
  var positionY: Float
  var velocityX: Float
  var velocityY: Float
  var size: Int32
  var zero1: Int32
  var angle: Float
  var majorAxis: Float
  var minorAxis: Float
  var absolutePositionX: Float
  var absolutePositionY: Float
  var absoluteVelocityX: Float
  var absoluteVelocityY: Float
  var zero2: Int32
  var zero3: Int32
  var zDensity: Float
}

nonisolated let mtTouchSize = 96
nonisolated let mtTouchStateMake: Int32 = 4
nonisolated let mtTouchStateTouching: Int32 = 5

typealias MTContactCallback = @convention(c) (
  UnsafeMutableRawPointer, UnsafeMutableRawPointer, Int32, Double, Int32
) -> Int32
typealias MTDeviceCreateListFunction = @convention(c) () -> Unmanaged<CFArray>?
typealias MTRegisterFunction = @convention(c) (UnsafeMutableRawPointer, MTContactCallback) -> Void
typealias MTDeviceStartFunction = @convention(c) (UnsafeMutableRawPointer, Int32) -> Int32
typealias MTDeviceStopFunction = @convention(c) (UnsafeMutableRawPointer) -> Int32
