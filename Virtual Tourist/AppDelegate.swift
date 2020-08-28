//
//  AppDelegate.swift
//  Virtual Tourist
//
//  Created by Justin Kumpe on 8/16/20.
//  Copyright © 2020 Justin Kumpe. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
//		Set dataController to be injected
    let dataController = DataController(modelname: "Virtual_Tourist")

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
//			Load dataController
			dataController.load()
        
//			Inject dataController into first ViewController
        let navagationController = window?.rootViewController as! UINavigationController
        let locationsMapViewController = navagationController.topViewController as! LocationsMapViewController
        locationsMapViewController.dataController = dataController
        return true
    }
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        saveViewContext()
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        saveViewContext()
    }

    
  

    // MARK: - Core Data Saving support

    func saveViewContext () {
        let context = dataController.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
//    MARK: checkIfFirstLaunch
    
    func checkIfFirstLaunch(){
        if UserDefaults.standard.bool(forKey: "HasLaunchedBefore"){
            Logger.log(.success, "Not First Launch")
        }else{
            Logger.log(.action, "Is First Launch")
        }
    }

}

