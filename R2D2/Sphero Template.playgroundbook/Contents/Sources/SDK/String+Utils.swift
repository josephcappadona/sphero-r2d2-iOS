//
//  String+Utils.swift
//  SupportingContent
//
//  Created by Jeff Payan on 2018-08-08.
//  Copyright © 2018 Sphero Inc. All rights reserved.
//

import Foundation

extension String {
    var nullTerminated: [UInt8]? {
        if var data = self.data(using: String.Encoding.utf8) {
            data.append(0)
            return Array(data)
        }
        return nil
    }
}
