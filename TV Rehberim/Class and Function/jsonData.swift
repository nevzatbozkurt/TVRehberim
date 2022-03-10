//
//  class.swift
//  Alanyaspor
//
//  Created by Nevzat BOZKURT on 23.09.2018.
//  Copyright © 2018 Nevzat BOZKURT. All rights reserved.
//

import UIKit
import SwiftyJSON


class Channels {
    var title: String?
    var id: Int?
    var category: String?
    
    init(json: JSON) {
        self.title = json["Title"].string
        self.id = json["Id"].int
        self.category = json["Category"].string
    }
}


//Channel Detail View START\\

class Days {
    var title : String?
    var programme = [Programme]()
    
    //arama için
    init(title: String, programme: [Programme]) {
        self.title = title
        self.programme = programme
    }
    
    //ilk veri çekmede kullanılması için
    init(json: JSON) {
        self.title = json["title"].stringValue
        for prg in json["programme"].arrayValue{
            self.programme.append(Programme(json: prg))
        }
    }
}


class Programme  {
    var detailID : String?
    var name : String?
    var info : String?
    var datetime : Int?
    var time : String?
    let formatter = DateFormatter()
    
    
    init(json: JSON) {
        self.detailID = json["detailID"].stringValue
        self.name =  json["name"].stringValue
        self.info = json["info"].stringValue
        self.datetime = json["datetime"].intValue
        //zaman kodunu saat cinsine donusturuyorum
        let date = Date(timeIntervalSince1970:  TimeInterval(json["datetime"].intValue))
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = TimeZone(abbreviation: "GTM+3")
        let timeZoneStr = formatter.string(from: date)
        //bitti
        self.time = timeZoneStr
    }
    
}
//Channel Detail View END\\


