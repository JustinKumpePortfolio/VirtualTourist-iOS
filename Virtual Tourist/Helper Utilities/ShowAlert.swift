//
//  ShowAlert.swift
//  Virtual Tourist
//
//  Created by Justin Kumpe on 8/17/20.
//  Copyright © 2020 Justin Kumpe. All rights reserved.
//

import UIKit

/* MARK: ShowAlert
 Class to hold reusable UIAlerts
*/
class ShowAlert {

//    Display alert with OK Button
    static func error(viewController: UIViewController, title: String, message: String) {
        // Ensure alert is called on Main incase it is called from background
        dispatchOnMain {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            viewController.present(alert, animated: true, completion: nil)
        }
    }

//    Display alert with completion block
    static func alertDestructive(viewController: UIViewController, title: String, message: String, okButton: String = "Ok", cancelbutton: String = "Cancel", completion: @escaping (Bool) -> Void){
        dispatchOnMain {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: okButton, style: .destructive, handler: {(alert: UIAlertAction!) in completion(true)}))
            alert.addAction(UIAlertAction(title: cancelbutton, style: .default, handler: {(alert: UIAlertAction!) in completion(false)}))
            viewController.present(alert, animated: true, completion: nil)
        }
    }
    //TODO: Create function for ok/cancel alert with completion handler
}
