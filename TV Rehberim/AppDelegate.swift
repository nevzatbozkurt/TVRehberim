//
//  AppDelegate.swift
//  TV Rehberim
//
//  Created by Nevzat BOZKURT on 6.01.2019.
//  Copyright © 2019 Nevzat BOZKURT. All rights reserved.
//

import UIKit
import GoogleMobileAds


var notifProgrammeID = "" //bildirimden gelen idyi tutup ona göre işlem yapmak için.
let myAppStoreUrl = "itms-apps://itunes.apple.com/app/id1451708806" //uygulamaya link vereceğim yerler için
let backendUrl = ""

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    //bildirime tıklayınca yapacaklarımız
    func application(_ app: UIApplication, didReceive notif: UILocalNotification) {
        if let userInfo = notif.userInfo {
            notifClicked(userInfo: userInfo as! [String : String])
        }
    }
    
    func notifClicked(userInfo: [String:String]){
        let rootViewController = self.window!.rootViewController as! UITabBarController
        notifProgrammeID = userInfo["ID"]!
        rootViewController.selectedIndex = 0 //eger 1. ekranda arka plana attıysa viewDidAppear fonksiyonu yeniden acilinca calismiyordu bunu ekleyerek farklı ekrana gecip tekrar aciyoruz calisiyor.
        rootViewController.selectedIndex = 1
    }
    //bitti
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        application.registerUserNotificationSettings(UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)) //yerel bildirimler için izin istiyoruz.
        
        let localNotif = launchOptions?[.localNotification] as? UILocalNotification
        if let userInfo = localNotif?.userInfo {
            notifClicked(userInfo: userInfo as! [String : String])
        }
        getRemindProgramme()
        
        // [START tracker_swift]
        guard let gai = GAI.sharedInstance() else {
            assert(false, "Google Analytics not configured correctly")
            return true//Base on your function return type, it may be returning something else
        }
        gai.tracker(withTrackingId: "UA-137864942-3")
        // Optional: automatically report uncaught exceptions.
        gai.trackUncaughtExceptions = true
        // [END tracker_swift]
        
        // [START ads]
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        // [END ads]
        
        //puanlama yapmasi icin teşvik..
        StoreReviewHelper.incrementAppOpenedCount()
        StoreReviewHelper.checkAndAskForReview()
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        saveRemindProgramme()//arka plana geçerken veya kapatırken kaydedilmeyen varsa diye garanti olması adına kayıt yapıyorum
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
 
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        //getRemindProgramme()//arka planda gelince geçmiş tarihli bildirim varsa onları temizliyoruz.

        changeBadge(itemIndex: 1, newValue: remindProgramme.count)
        
    }
    
    
    
   

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
       
    }


}

