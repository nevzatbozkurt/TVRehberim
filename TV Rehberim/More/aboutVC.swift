//
//  aboutVC.swift
//  TV Rehberim
//
//  Created by Nevzat BOZKURT on 4.02.2019.
//  Copyright © 2019 Nevzat BOZKURT. All rights reserved.
//

import UIKit

class aboutVC: ViewControllerPannable {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        dismiss(animated: false, completion: nil) //farklı bir alt menüye geçince popView yani bu sayfa açık kaldıysa bir bug oluyordu bizde farklı bir sayfaya geçiş olursa (bu fonk. çalışıyor) açık bırakılmış popup varsa kapatıyoruz.
    }

    @IBAction func close(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
