//
//  CollectionViewCell.swift
//  Photo Editor
//
//  Created by Md Hosne Mobarok on 18/3/22.
//

import UIKit

class CollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var editedImageView: UIImageView!
    @IBOutlet weak var filterName: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        editedImageView.layer.cornerRadius = 5
    }
    
}
