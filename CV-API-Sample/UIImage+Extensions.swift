//
//  UIImage+Extensions.swift
//  CV-API-Sample
//
//  Created by Clement DAL PALU on 11/9/17.
//  Copyright © 2017 Blippar. All rights reserved.
//

import UIKit
import CoreGraphics

extension UIImage {
	func resize(_ toSize: CGRect) -> UIImage {
		let size = self.size

		let widthRatio = toSize.width / self.size.width
		let heightRatio = toSize.height / self.size.height

		var newSize: CGSize
		if widthRatio > heightRatio {
			newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
		} else {
			newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
		}

		let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)

		UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
		self.draw(in: rect)
		let newImage = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()

		return newImage!
	}
}
