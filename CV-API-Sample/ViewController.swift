//
//  ViewController.swift
//  CV-API-Sample
//
//  Created by Clement DAL PALU on 11/10/17.
//  Copyright © 2017 Blippar. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCapturePhotoCaptureDelegate {

	private var captureSession: AVCaptureSession?
	private var capturePhotoOutput: AVCapturePhotoOutput?
	private var previewLayer: AVCaptureVideoPreviewLayer?
	private var blipparUtilsInstance: BlipparUtils?
	private var snapButton: UIButton?

	// REMOVE THIS LINE
	private var resultView: UITextView?

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		if let captureDevice = AVCaptureDevice.default(for: .video) {
			do {
				let input = try AVCaptureDeviceInput(device: captureDevice)

				// Capture session init
				self.captureSession = AVCaptureSession()
				self.captureSession?.addInput(input)

				// Get a session of AVCapturePhotoOutput
				self.capturePhotoOutput = AVCapturePhotoOutput()
				self.capturePhotoOutput?.isHighResolutionCaptureEnabled = true

				// Set the output on the capture session
				self.captureSession?.addOutput(self.capturePhotoOutput!)

				// VideoPreviewLayer init
				self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession!)
				self.previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
				self.previewLayer?.frame = self.view.layer.bounds
				self.view.layer.addSublayer(self.previewLayer!)

				// Start capture
				self.captureSession?.startRunning()
			} catch {
				print("Error while trying to get capture device: \(error)")
			}
		}

		self.snapButton = UIButton(frame: CGRect(
			x: (self.view.frame.width / 2) - 45,
			y: self.view.frame.height - 100,
			width: 90,
			height: 90)
		)
		self.snapButton?.setImage(UIImage(named: "snapButton"), for: .normal)
		self.snapButton?.setImage(UIImage(named: "snapButtonOn"), for: .highlighted)
		self.snapButton?.addTarget(self, action: #selector(viewTapped(_:)), for: .touchUpInside)

		self.blipparUtilsInstance = BlipparUtils.sharedInstance

		// REMOVE THESE LINES
		self.resultView = UITextView(frame: self.view.frame)
		self.resultView?.isEditable = false
		self.resultView?.backgroundColor = .clear
		self.resultView?.textColor = .red
	}

	override func viewWillLayoutSubviews() {
		// REMOVE THIS LINE
		self.view.addSubview(self.resultView!)

		self.view.addSubview(self.snapButton!)
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	@objc func viewTapped(_ sender: UITapGestureRecognizer) {
		let photoSettings = AVCapturePhotoSettings()
		photoSettings.isAutoStillImageStabilizationEnabled = true
		photoSettings.isHighResolutionPhotoEnabled = true
		photoSettings.flashMode = .off

		self.capturePhotoOutput?.capturePhoto(with: photoSettings, delegate: self)
	}

	func displayResults(_ results: [BlipparEntity]) {
		var resultStr = ""
		for result in results {
			guard let type = result.MatchTypes?.first else {
				continue
			}
			guard let name = result.DisplayName else {
				continue
			}
			resultStr.append("\(type): \(name)\n")
		}
		DispatchQueue.main.async {
			self.resultView?.text = resultStr
		}
	}

	// MARK: AVCapturePhotoCaptureDelegate

	func photoOutput(_ captureOutput: AVCapturePhotoOutput,
					 didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?,
					 previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?,
					 resolvedSettings: AVCaptureResolvedPhotoSettings,
					 bracketSettings: AVCaptureBracketedStillImageSettings?,
					 error: Error?) {
		if error != nil {
			print("Error while capturing photo output: \(String(describing: error))")
			return
		}

		if let imageData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: photoSampleBuffer!, previewPhotoSampleBuffer: previewPhotoSampleBuffer) {
			if let image = UIImage(data: imageData) {
				let resizedImage = image.resize(CGRect(x: 0, y: 0, width: 300, height: image.size.height / 300 * image.size.width))
				self.blipparUtilsInstance?.sendImageLookupRequest(resizedImage) { (results, error) in
					if let err = error {
						print("Error while sending image lookup request: \(err.localizedDescription)")
						return
					}
					
					// REMOVE THIS LINE
					self.displayResults(results!)
				}
			}
		}

	}
}
