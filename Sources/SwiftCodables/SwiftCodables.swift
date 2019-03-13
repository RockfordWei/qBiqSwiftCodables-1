//
//  SwiftCodables.swift
//  Biq
//
//  Created by Kyle Jessup on 2017-12-05.
//

import Foundation

/// An account unique id.
public typealias UserId = UUID
/// A qBiq device id.
public typealias DeviceURN = String
/// A unique id for a group of qBiqs.
public typealias GroupId = UUID

/// A type with a hashable `id` property.
public protocol IdHashable: Hashable {
	/// The type of the object id.
	associatedtype IdType: Hashable
	/// The id for this object.
	var id: IdType { get }
}

extension IdHashable {
	/// Delegates hash to `id`
	public var hashValue: Int {
		return id.hashValue
	}
	/// Objects equate if their ids are equivalent.
	public static func ==(lhs: Self, rhs: Self) -> Bool {
		return lhs.id == rhs.id
	}
}

/// Namespace around observation database.
public enum ObsDatabase {
	/// qBiq observation database table.
	public struct BiqObservation: Codable {
		/// Serial number of the observation.
		public let id: Int
		/// The id of the device which made the observtion.
		public var deviceId: DeviceURN { return bixid }
		/// The id of the device which made the observation (historical).
		public let bixid: DeviceURN
		/// The time of the observation in milliseconds since Jan 1, 1970
		public let obstime: Double
		/// The time of the observation in seconds since Jan 1, 1970
		/// !FIX! I don't know why they are stored in the db as milliseconds and as a Double
		public var obsTimeSeconds: Double { return obstime / 1000 }
		/// One or zero depending on if the qBiq is currently charging.
		/// Note that a qBiq may be plugged in but not currently charging, depending on its battery level.
		public let charging: Int
		/// The qBiq's EFM firmware version.
		public let firmware: String
		/// The qBiq's ESP firmware version.
		public let wifiFirmware: String?
		/// The qBiq's current battery level in volts.
		public let battery: Double
		/// The observed temperature.
		public let temp: Double
		/// The observed light level.
		public let light: Int
		/// The observed humidity level.
		public let humidity: Int
		/// The observed x acceleration.
		/// NOTE: these are soon to be obsoleted or at least radically changed.
		public let accelx: Int
		/// The observed z acceleration.
		/// NOTE: these are soon to be obsoleted or at least radically changed
		public let accely: Int
		/// The observed y acceleration.
		/// NOTE: these are soon to be obsoleted or at least radically changed.
		public let accelz: Int
		/// Initialize a new observation struct.
		public init(id i: Int,
					deviceId d: DeviceURN,
					obstime: Double,
					charging: Int,
					firmware: String,
					wifiFirmware: String,
					battery: Double,
					temp: Double,
					light: Int,
					humidity: Int,
					accelx: Int,
					accely: Int,
					accelz: Int) {
			id = i
			bixid = d
			self.obstime = obstime
			self.charging = charging
			self.firmware = firmware
			self.wifiFirmware = wifiFirmware
			self.battery = battery
			self.temp = temp
			self.light = light
			self.humidity = humidity
			self.accelx = accelx
			self.accely = accely
			self.accelz = accelz
		}
	}
}

/// Bit flags for biq status and capabilities.
public struct BiqDeviceFlag: OptionSet {
	/// The bit for this flag.
	public let rawValue: Int
	/// Init with raw value.
	public init(rawValue r: Int) {
		rawValue = r
	}
	/// If set, the biq's data is private and can only be shared with a share code.
	public static let locked = BiqDeviceFlag(rawValue: 1)
	/// If set, the qBiq is capable of sensing and reporting on temperature.
	public static let temperatureCapable = BiqDeviceFlag(rawValue: 1<<2)
	/// If set, the qBiq is capable of sensing and reporting on movement.
	public static let movementCapable = BiqDeviceFlag(rawValue: 1<<3)
	/// If set, the qBiq is capable of sensing and reporting on ambient light intensity.
	public static let lightCapable = BiqDeviceFlag(rawValue: 1<<4)
}

/// qBiq device table.
public struct BiqDevice: Codable, IdHashable {
	/// The permanent unique id for this qBiq device.
	public let id: DeviceURN
	/// The owner specified name for this device.
	public let name: String
	/// The owner of the device.
	/// Unowned devices will have nil owner.
	public let ownerId: UserId?
	/// The raw capability flags for this device.
	public let flags: Int?
	/// The latitude at which the qBiq was last scanned.
	public let latitude: Double?
	/// The longitude at which the qBiq was last scanned.
	public let longitude: Double?
	/// Used for some joins. The groups contianing the qBiq.
	public let groupMemberships: [BiqDeviceGroupMembership]?
	/// Used for some joins. The users with access to the device's data.
	public let accessPermissions: [BiqDeviceAccessPermission]?
	/// The capability flags for this device.
	public var deviceFlags: BiqDeviceFlag {
		return BiqDeviceFlag(rawValue: flags ?? 0)
	}
	/// Init a new BiqDevice struct.
	public init(id i: DeviceURN,
				name n: String,
				ownerId o: UserId? = nil,
				flags f: BiqDeviceFlag? = nil,
				latitude la: Double? = nil,
				longitude lo: Double? = nil) {
		id = i
		name = n
		ownerId = o
		flags = f?.rawValue
		latitude = la
		longitude = lo
		
		groupMemberships = nil
		accessPermissions = nil
	}
}

/// A user controlled group of qBiqs.
public struct BiqDeviceGroup: Codable, IdHashable {
	/// The unique id for the group.
	public let id: GroupId
	/// The owner of the group.
	public let ownerId: UserId
	/// The name of the group.
	public let name: String
	/// The devices in the group.
	public let devices: [BiqDevice]?
	/// Init a new BiqDeviceGroup.
	public init(id i: GroupId,
				ownerId o: UserId,
				name n: String) {
		id = i
		ownerId = o
		name = n
		devices = nil
	}
}

/// Junction table indicating group membership.
public struct BiqDeviceGroupMembership: Codable {
	/// The id of the group.
	public let groupId: GroupId
	/// The id of the device.
	public let deviceId: DeviceURN
	/// Init a BiqDeviceGroupMembership
	public init(groupId g: GroupId,
				deviceId d: DeviceURN) {
		groupId = g
		deviceId = d
	}
}

/// Junction table giving access permission for a qBiq. Represents a shared qBiq.
public struct BiqDeviceAccessPermission: Codable {
	/// The id of the user to which the qBiq is shared.
	public let userId: UserId
	/// The id of the device in the group.
	public let deviceId: DeviceURN
	/// Flags for the shared qBiq.
	/// !FIX! is this used?
	public let flags: Int?
	/// Init a BiqDeviceAccessPermission
	public init(userId u: UserId,
				deviceId d: DeviceURN,
				flags f: Int = 0) {
		userId = u
		deviceId = d
		flags = f
	}
}

/// Available temperature qBiq scales.
public enum TemperatureScale: Int {
	/// C
	case celsius,
	/// F
		fahrenheit
}

/// A type of setting or limit on a qBiq.
public struct BiqDeviceLimitType: Codable {
	/// Raw value of the limit.
	public let rawValue: UInt8
	/// Init with raw value.
	public init(rawValue: UInt8) {
		self.rawValue = rawValue
	}
	/// Decode from single value.
	public init(from decoder: Decoder) throws {
		let d = try decoder.singleValueContainer()
		self.init(rawValue: try d.decode(UInt8.self))
	}
	/// Encode to single value.
	public func encode(to encoder: Encoder) throws {
		var c = encoder.singleValueContainer()
		try c.encode(rawValue)
	}
	/// High temperature threshold.
	public static let tempHigh = 		BiqDeviceLimitType(rawValue: 0)
	/// Low temperature threshold.
	public static let tempLow = 		BiqDeviceLimitType(rawValue: 1)
	/// Movement sensitivity threshold.
	public static let movementLevel = 	BiqDeviceLimitType(rawValue: 2)
	/// Battery low level threshold.
	public static let batteryLevel = 	BiqDeviceLimitType(rawValue: 3)
	/// Notifications frequency for this device/user combination.
	public static let notifications = 	BiqDeviceLimitType(rawValue: 4)
	/// Desired temperature scale (C/F).
	public static let tempScale = 		BiqDeviceLimitType(rawValue: 5)
	/// Desired colour for the qBiq.
	/// Sets both the qBiq's represenation within the app and, for the owner, the qBiq's blinking LED colour during reports.
	public static let colour = 		BiqDeviceLimitType(rawValue: 6)
	/// Sets the qBiq's report interval.
	public static let interval = 		BiqDeviceLimitType(rawValue: 7)
	/// Sets the qBiq's report format.
	/// !FIX! switching to JSON from binary is not functional.
	public static let reportFormat = 	BiqDeviceLimitType(rawValue: 8)
	/// Maximum amount of data to be stored in the qBiq during periods in which it can not make a connection to report.
	public static let reportBufferCapacity = BiqDeviceLimitType(rawValue: 9)
	/// Sets the threshold for light level.
	public static let lightLevel = 	BiqDeviceLimitType(rawValue: 10)
	/// Sets the threshold for himidity level.
	public static let humidityLevel = 	BiqDeviceLimitType(rawValue: 11)
	/// Equate two limits.
	public static func ==(lhs: BiqDeviceLimitType, rhs: BiqDeviceLimitType) -> Bool {
		return lhs.rawValue == rhs.rawValue
	}
	/// Illequate two limits.
	public static func !=(lhs: BiqDeviceLimitType, rhs: BiqDeviceLimitType) -> Bool {
		return lhs.rawValue != rhs.rawValue
	}
}

/// A flag on a limit.
public struct BiqDeviceLimitFlag: Codable, OptionSet {
	/// Raw value.
	public let rawValue: UInt8
	/// Init a BiqDeviceLimitFlag
	public init(rawValue: UInt8) {
		self.rawValue = rawValue
	}
	/// Decode from single value.
	public init(from decoder: Decoder) throws {
		let d = try decoder.singleValueContainer()
		self.init(rawValue: try d.decode(UInt8.self))
	}
	/// Encode to single value.
	public func encode(to encoder: Encoder) throws {
		var c = encoder.singleValueContainer()
		try c.encode(rawValue)
	}
	
	/// No flag.
	public static let none = BiqDeviceLimitFlag(rawValue: 0)
	/// Shared by owner and included in standard limit's fetch.
	/// Can only be set on owned device.
	public static let ownerShared = BiqDeviceLimitFlag(rawValue: 1 << 0)
}

/// A setting or limit on a qBiq.
public struct BiqDeviceLimit: Codable {
	/// Id of the user who the limit belongs to.
	public let userId: UserId
	/// Id of the device the limit is set on.
	public let deviceId: DeviceURN
	/// The raw type of the limit.
	public let limitType: UInt8
	/// The value for the limit.
	/// This may be zero and ignored for limits which have an associated string value.
	public let limitValue: Float
	/// The optional string value for this limit.
	public let limitValueString: String?
	/// The limit type.
	public var type: BiqDeviceLimitType { return BiqDeviceLimitType(rawValue: limitType) }
	/// Flag modifier for limit.
	public let limitFlag: UInt8?
	/// The limit flag.
	public var flag: BiqDeviceLimitFlag {
		guard let lf = limitFlag else {
			return .none
		}
		return BiqDeviceLimitFlag(rawValue: lf)
	}
	
	/// Init a BiqDeviceLimit.
	public init(userId u: UserId,
				deviceId d: DeviceURN,
				limitType t: BiqDeviceLimitType,
				limitValue v: Float = 0.0,
				limitValueString vs: String? = nil,
				limitFlag lf: BiqDeviceLimitFlag) {
		userId = u
		deviceId = d
		limitType = t.rawValue
		limitValue = v
		limitValueString = vs
		limitFlag = lf.rawValue
	}
}

/// A setting or limit which will be pushed to the device the next time is checks in.
/// Only device owners end up setting push limits and only some limit types become push limits.
public struct BiqDevicePushLimit: Codable {
	/// The device id.
	public let deviceId: DeviceURN
	/// The raw type of the limit.
	public let limitType: UInt8
	/// The value for the limit.
	/// This may be zero and ignored for limits which have an associated string value.
	public let limitValue: Float
	/// The optional string value for this limit.
	public let limitValueString: String?
	/// The limit type.
	public var type: BiqDeviceLimitType? { return BiqDeviceLimitType(rawValue: limitType) }
	/// Init a BiqDevicePushLimit
	public init(deviceId d: DeviceURN, limitType t: BiqDeviceLimitType, limitValue v: Float = 0.0, limitValueString vs: String? = nil) {
		deviceId = d
		limitType = t.rawValue
		limitValue = v
		limitValueString = vs
	}
}

/// A table of firmware versions used to control OTA qBiq upgrades.
public struct BiqDeviceFirmware: Codable {
	/// The version string.
	public let version: String
	/// The firmware type. 0 = EFM, 1 = ESP.
	public let type: Int
	/// The previous version.
	public let supersedes: String?
	/// The next version, if any.
	public let obsoletedBy: String?
	/// Init a BiqDeviceFirmware
	public init(version: String, type: Int, supersedes: String?, obsoletedBy: String?) {
		self.version = version
		self.type = type
		self.supersedes = supersedes
		self.obsoletedBy = obsoletedBy
	}
}

/// Request and response objects for the groups API.
public enum GroupAPI {
	/// Request to create a group of qBiqs.
	public struct CreateRequest: Codable {
		/// The name for the new group.
		public let name: String
		/// Init a CreateRequest
		public init(name h: String) {
			name = h
		}
	}
	/// Request to delete a group of qBiqs.
	public struct DeleteRequest: Codable {
		/// The id of the group to delete.
		/// User must be the group's owner.
		public let groupId: GroupId
		/// Init a DeleteRequest.
		public init(groupId h: GroupId) {
			groupId = h
		}
	}
	/// Request to update a group. Currently only supports updating the group's name.
	public struct UpdateRequest: Codable {
		/// The id of the group to update.
		// Usser must be the group's owner.
		public let groupId: GroupId
		/// The optional new name for the group.
		public let name: String?
		/// Init a UpdateRequest.
		public init(groupId g: GroupId, name n: String? = nil) {
			groupId = g
			name = n
		}
	}
	/// List devices which belong to the group.
	public struct ListDevicesRequest: Codable {
		/// The id of the group to list.
		/// User must be the owner of the group.
		public let groupId: GroupId
		/// Init a ListDevicesRequest.
		public init(groupId h: GroupId) {
			groupId = h
		}
	}
	/// Request to add a device to a group.
	public struct AddDeviceRequest: Codable {
		/// The id of the group to which the device should be added.
		/// User must be the owner of the group.
		public let groupId: GroupId
		/// The id of the device to add.
		public let deviceId: DeviceURN
		/// Init a AddDeviceRequest.
		public init(groupId h: GroupId, deviceId d: DeviceURN) {
			groupId = h
			deviceId = d
		}
	}
}

/// Request and response objects for device API.
public enum DeviceAPI {
	/// Request type used for several API calls in which a simple device id is required.
	public struct GenericDeviceRequest: Codable {
		/// The device id.
		public let deviceId: DeviceURN
		/// Init a GenericDeviceRequest.
		public init(deviceId d: DeviceURN) {
			deviceId = d
		}
	}
	/// Request to register a device.
	public typealias RegisterRequest = GenericDeviceRequest
	/// Request to return the limits associated with a device.
	public typealias LimitsRequest = GenericDeviceRequest
	
	/// Request to share someone else's biq.
	/// Locked qBiqs require a share token. Unlocked, or open, qBiqs do not.
	public struct ShareRequest: Codable {
		/// The device id.
		public let deviceId: DeviceURN
		/// The optional share token.
		/// Share tokens can only be used once.
		public let token: UUID?
		/// Init a ShareRequest.
		public init(deviceId d: DeviceURN, token t: UUID? = nil) {
			deviceId = d
			token = t
		}
	}
	/// Request to produce a token which permits another person to share your qBiq's data.
	public struct ShareTokenRequest: Codable {
		/// The device for which the token will be generated.
		/// User must be the owner of the device.
		public let deviceId: DeviceURN
		/// Init a ShareTokenRequest.
		public init(deviceId d: DeviceURN) {
			deviceId = d
		}
	}
	/// Response for a share token request.
	public struct ShareTokenResponse: Codable {
		/// The share token which can be usaed by another user to share the device.
		public let token: UUID
		/// Init a ShareTokenResponse.
		public init(token t: UUID) {
			token = t
		}
	}
	/// Request to update various properties of a qBiq.
	public struct UpdateRequest: Codable {
		/// The id of the device.
		/// User must devcie owner.
		public let deviceId: DeviceURN
		/// Optional new name for the device.
		/// Ignored if nil.
		public let name: String?
		/// New raw flags for device.
		/// Note that not all flags can be explicitly set; currently only `.locked`.
		public let flags: Int?
		/// Flags for device.
		public var deviceFlags: BiqDeviceFlag? {
			if let f = flags {
				return BiqDeviceFlag(rawValue: f)
			}
			return nil
		}
		/// Init a UpdateRequest.
		public init(deviceId g: DeviceURN, name n: String? = nil, flags f: BiqDeviceFlag? = nil) {
			deviceId = g
			name = n
			flags = f?.rawValue
		}
	}
	/// Returned in device limit responses.
	public struct DeviceLimit: Codable {
		/// The type of limit.
		public let limitType: BiqDeviceLimitType
		/// The optional float value for the limit.
		public let limitValue: Float?
		/// The optional string value for the limit.
		public let limitValueString: String?
		/// Flag for the limit
		public let limitFlag: BiqDeviceLimitFlag?
		/// Init a DeviceLimit.
		public init(limitType t: BiqDeviceLimitType,
					limitValue v: Float?,
					limitValueString vs: String? = nil,
					limitFlag lf: BiqDeviceLimitFlag?) {
			limitType = t
			limitValue = v
			limitValueString = vs
			limitFlag = lf
		}
	}
	/// Request to update indicated device limits.
	/// Limits with a nil `limitValue` or `limitValueString` indicate that the limit should be deleted.
	public struct UpdateLimitsRequest: Codable {
		/// The device id.
		public let deviceId: DeviceURN
		/// The array of limits to set.
		public let limits: [DeviceLimit]
		/// Init a UpdateLimitsRequest.
		public init(deviceId g: DeviceURN, limits l: [DeviceLimit]) {
			deviceId = g
			limits = l
		}
	}
	/// Response indicating all limits for a particular device.
	public typealias DeviceLimitsResponse = UpdateLimitsRequest
	/// An item in a list of devices response.
	public struct ListDevicesResponseItem: Codable {
		/// The device for this item.
		public let device: BiqDevice
		/// The last observation recorded for the device.
		public let lastObservation: ObsDatabase.BiqObservation?
		/// The number of people sharing the qBiq.
		/// Owner not included in the count.
		public let shareCount: Int?
		/// The limits which have been applied to the device by this user.
		public let limits: [DeviceLimit]?
		/// Init a ListDevicesResponseItem.
		public init(device d: BiqDevice, shareCount s: Int, lastObservation o: ObsDatabase.BiqObservation?, limits l: [DeviceLimit]) {
			device = d
			shareCount = s
			lastObservation = o
			limits = l
		}
	}
	/// A request for a list of device observations.
	public struct ObsRequest: Codable {
		/// The time interval for this observations are sought.
		public enum Interval: Int, Codable {
				/// All observations
				/// !FIX! for debugging. Remove this.
			case all,
				/// Return observations for the last 12 hours.
				/// These observations are not averaged.
				live,
				/// Returns observations from the last 24 hours with each hour of observations averaged.
				day,
				/// Returns observations from the last 30 days, with each day of observations averaged.
				month,
				/// Returns observations from the last 365 days, with each month of observations averaged.
				year
		}
		/// The device for which the observations are requested.
		/// User must be owner or have been shared the device.
		public let deviceId: DeviceURN
		/// Raw interval value.
		public let interval: Int // fix - enums with associated + codable
		/// Init a ObsRequest
		public init(deviceId d: DeviceURN, interval i: Interval) {
			deviceId = d
			interval = i.rawValue
		}
	}
}

/// A component of a device observation.
/// These values are the qBiq report element tags.
/// !FIX! are these used anymore?
public enum Observation {
	public enum Element: Int {
		case
		deviceId,
		firmwareVersion,
		batteryLevel,
		charging,
		temperature,
		lightLevel,
		relativeHumidity,
		relativeTemperature,
		acceleration // xyz
	}
}

/// Formatting and conversion for temperatures.
public extension BinaryFloatingPoint {
	/// Round number to one decimal place.
	var oneDecimalPlace: String {
		return String(format: "%.1f", Float(Float(Int(self * 10))/10))
	}
	/// Convert a Fahrenheit to Celsius
	var fahrenheit2Celsius: Self {
		return (self - 32) * 5 / 9
	}
	/// Convert a Celsius to Fahrenheit
	var celsius2Fahrenheit: Self {
		return self * 9 / 5 + 32
	}
	/// Round number to nearest .0 or .5, whichever is closer.
	var nearestFive: Self {
		return (self * 2).rounded() / 2
	}
}

/// Formatting and conversion for temperatures.
public extension TemperatureScale {
	/// Format the temperature according to this scale.
	/// The `temp` is assumed to be in this scale.
	func format<T: BinaryFloatingPoint>(_ temp: T) -> String {
		switch self {
		case .celsius:
			return "\(temp.oneDecimalPlace)ºC"
		case .fahrenheit:
			return "\(temp.oneDecimalPlace)ºF"
		}
	}
	/// Format the given celsuis temperature according to this scale.
	/// Temperature is converted from celsius if necessary.
	func formatC<T: BinaryFloatingPoint>(_ temp: T) -> String {
		return format(fromC(temp))
	}
	/// Converts the parameter to celsius if necessary.
	func asC<T: BinaryFloatingPoint>(_ d: T) -> T {
		guard !d.isNaN else {
			return d
		}
		switch self {
		case .celsius:
			return d
		case .fahrenheit:
			return d.fahrenheit2Celsius
		}
	}
	/// Converts the parameter from celsius if necessary.
	func fromC<T: BinaryFloatingPoint>(_ d: T) -> T {
		guard !d.isNaN else {
			return d
		}
		switch self {
		case .celsius:
			return d
		case .fahrenheit:
			return d.celsius2Fahrenheit
		}
	}
	/// Temperature indicator suffix.
	var suffix: String {
		switch self {
		case .celsius:
			return "C"
		case .fahrenheit:
			return "F"
		}
	}
}
