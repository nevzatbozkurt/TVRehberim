//
//  channelTVCell.swift
//  TV Rehberim
//
//  Created by Nevzat BOZKURT on 18.01.2019.
//  Copyright © 2019 Nevzat BOZKURT. All rights reserved.
//

import UIKit

//set alarm start
protocol setAlarmProtocol {
    func setAlarm(index: IndexPath)
}
//set alarm end

class channelTVCell: UITableViewCell {

    var delegate: setAlarmProtocol?
    var index: IndexPath?
    
    @IBOutlet weak var programmeTitleLabel: UILabel!
    @IBOutlet weak var programmeInfoTextView: UITextView!
    @IBOutlet weak var programmeTimeLabel: UILabel!
    @IBOutlet weak var alarmButton: UIButton!
    @IBOutlet weak var programmeProgressView: UIView!
    @IBAction func btnAlarm(_ sender: UIButton) {
        delegate?.setAlarm(index: (index)!)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }

    
    
    
}
