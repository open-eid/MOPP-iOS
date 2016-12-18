//
//  MoppLibTest.swift
//  MoppLib
//
//  Created by Ants Käär on 15.12.16.
//  Copyright © 2016 Mobi Lab. All rights reserved.
//

import Foundation
import MBProgressHUD

public class MoppLibTest: NSObject {
  
  public static func testString() -> String {
    
    ObjCPP.testMethod()
    
    let view = UIView.init()
    MBProgressHUD.hide(for: view, animated: true)
    return "MoppLib testString"
  }
}
