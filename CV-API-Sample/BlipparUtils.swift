//
//  BlipparUtils.swift
//  CV-API-Sample
//
//  Created by Clement DAL PALU on 10/6/17.
//  Copyright © 2017 Blippar. All rights reserved.
//

import Foundation
import UIKit

private let authBaseURL = "https://bauth.blippar.com/token"
private let recoBaseURL = "https://bapi.blippar.com"

/// BlipparUtils manages all interactions with Blippar servers
class BlipparUtils {
	/// Shared instance reused across the entire app
	static let sharedInstance = BlipparUtils()
	private var accessToken: String = ""
	private var expirationDate: Date = Date()

	private init() {
		self.requestAccessToken()
	}

	private func requestAccessToken() {
		if let path = Bundle.main.url(forResource: "CV-API", withExtension: "plist") {
			do {
				let data = try Data(contentsOf: path)
				let credentials = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as! [String: String]
				let urlString = String(format: "%@?grant_type=client_credentials&client_id=%@&client_secret=%@", authBaseURL, credentials["client_id"]!, credentials["client_secret"]!)
				let session = URLSession(configuration: URLSessionConfiguration.default)
				let task = session.dataTask(with: URL(string: urlString)!) { (data, urlResponse, error) in
					if error != nil {
						print("Error while fetching access token: \(error!)")
						return
					} else if let response = urlResponse as? HTTPURLResponse, response.statusCode != 200 {
						print("Error while fetching access token: Got \(response.statusCode) status code")
						return
					}
					do {
						let authResponse = try JSONDecoder().decode(BlipparAuthResponse.self, from: data!)
						self.accessToken = "\(authResponse.token_type) \(authResponse.access_token)"
						self.expirationDate = Date().addingTimeInterval(TimeInterval(authResponse.expires_in))
					} catch {
						print("Error while decoding BlipparAuthResponse: \(error)")
					}

				}
				task.resume()
			} catch {
				print("Error while fetching access token: \(error)")
			}
		}
	}

	public func sendImageLookupRequest(
		_ image: UIImage,
		location: String = "",
		locationAccuracy: String = "",
		completion: @escaping (_ results: [BlipparEntity]?, _ error: Error?) -> Void) {
		let imageData: Data = UIImageJPEGRepresentation(image, 1.0)!
		let urlString = String("\(recoBaseURL)/v1/imageLookup")
		let BOUNDARY = "Boundary-\(UUID().uuidString)"
		let body: NSMutableString = NSMutableString()
		let endBody: NSMutableString = NSMutableString()
		let requestData: NSMutableData = NSMutableData()
		let device = UIDevice.current
		let deviceOrientation = device.orientation
		var angle = Int(0)

		switch deviceOrientation {
		case UIDeviceOrientation.landscapeLeft:
			angle = 90
		case UIDeviceOrientation.landscapeRight:
			angle = 270
		case UIDeviceOrientation.portraitUpsideDown:
			angle = 180
		default:
			angle = 0
		}

		var request = URLRequest(url: URL(string: urlString)!)
		request.httpMethod = "POST"
		request.addValue("application/json", forHTTPHeaderField: "Accept")
		request.addValue(self.accessToken, forHTTPHeaderField: "Authorization")
		request.addValue("\(angle)", forHTTPHeaderField: "CameraSensorOrientation")
		request.addValue(location, forHTTPHeaderField: "LatLong")
		request.addValue(locationAccuracy, forHTTPHeaderField: "LatLongAccuracy")
		request.addValue("en-US", forHTTPHeaderField: "Language")
		request.addValue("iOS", forHTTPHeaderField: "DeviceOS")
		request.addValue(device.model, forHTTPHeaderField: "DeviceType")
		request.addValue(device.systemVersion, forHTTPHeaderField: "DeviceVersion")
		request.addValue(String(format: "%d", angle), forHTTPHeaderField: "DeviceOrientation")
		request.addValue((device.identifierForVendor?.uuidString)!, forHTTPHeaderField: "UniqueID")
		request.addValue("0.0, -9.8, 0.0", forHTTPHeaderField: "Accelerometer")
		request.addValue("0.0, 0.0, 0.0", forHTTPHeaderField: "Gyro")
		request.addValue(String("multipart/form-data; boundary=\(BOUNDARY)"), forHTTPHeaderField: "Content-Type")

		body.append("--\(BOUNDARY)")
		body.append("Content-Disposition: form-data; name=\"data_separation\"\r\n\r\n")
		body.append("1\r\n")
		body.append("--\(BOUNDARY)\r\n")
		body.append("Content-Disposition: form-data; name=\"input_image\"; filename=\"capture.jpg\"\r\n")
		body.append("Content-Type: image/jpg\r\n\r\n")
		requestData.append(body.data(using: String.Encoding.utf8.rawValue)!)
		requestData.append(imageData)
		endBody.append("\r\n--\(BOUNDARY)--\r\n")
		requestData.append(endBody.data(using: String.Encoding.utf8.rawValue)!)
		request.httpBody = requestData as Data

		let session = URLSession(configuration: URLSessionConfiguration.default)
		let task = session.dataTask(with: request) { (data, response, error) in
			if error != nil {
				completion(nil, error)
			} else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
				completion(nil, BlipparError.badStatusCode)
			} else {
				do {
					let results = try JSONDecoder().decode([BlipparEntity].self, from: data!)
					completion(results, nil)
				} catch {
					completion(nil, BlipparError.invalidJSON)
				}
			}
		}
		task.resume()
	}
}

struct BlipparEntity: Decodable {
	var ID: String
	var Name: String?
	var DisplayName: String?
	var ThumbnailURL: String?
	var MatchTypes: [String]?
	var Score: Double
}

private struct BlipparAuthResponse: Decodable {
	var token_type: String
	var access_token: String
	var expires_in: UInt
}

private struct BlipparAuthError: Decodable {
	var error: String
	var error_description: String
}

enum BlipparError: Error {
	case requestNotExecuted // = "Request could not be executed"
	case authenticationFailed // = "Authentication failed"
	case badStatusCode // = "Status code was not 200 OK"
	case invalidJSON // = "Invalid JSON format"
}
