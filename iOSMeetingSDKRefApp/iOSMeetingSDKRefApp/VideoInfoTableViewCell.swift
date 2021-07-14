//
//  VideoInfoTableViewCell.swift
//  iOSMeetingSDKRefApp
//
//  Created by Aaron Treinish on 5/12/21.
//

import UIKit

class VideoInfoTableViewCell: UITableViewCell {

    @IBOutlet weak var streamIdLabel: UILabel!
    @IBOutlet weak var siteLabel: UILabel!
    @IBOutlet weak var deviceNameLabel: UILabel!
    @IBOutlet weak var activeLabel: UILabel!
    @IBOutlet weak var codecNameLabel: UILabel!
    @IBOutlet weak var localLabel: UILabel!
    @IBOutlet weak var layoutLabel: UILabel!
    @IBOutlet weak var widthLabel: UILabel!
    @IBOutlet weak var heightLabel: UILabel!
    @IBOutlet weak var enableDisableVideoStreamButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
