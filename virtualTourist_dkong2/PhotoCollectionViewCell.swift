//
//  PhotoCollectionViewCell.swift
//  virtualTourist_dkong2
//
//  Created by Daniel Kong on 12/3/16.
//  Copyright © 2016 Daniel Kong. All rights reserved.
//

import Foundation
import UIKit

class PhotoCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var indicatorView: UIActivityIndicatorView!
    
    var loading: Bool = true {
        didSet {
            if loading {
                imageView.image = nil
                indicatorView.startAnimating()
            } else {
                indicatorView.stopAnimating()
            }
            indicatorView.hidden = !loading
        }
    }
    
    var photo: Photo? = nil {
        didSet {
            if let data = oldValue?.photoImage {
                self.imageView.image = UIImage(data: data)
            } else {
                oldValue?.cancelRequestLoadingImage()
                loading = true
                photo?.startLoadingImage({ (image, error) -> Void in
                    self.loading = error != nil
                    self.imageView.image = image
                })
            }
        }
    }
    
    var business: Business? = nil {
        didSet {
            if let businessImageData = business?.imageData {
                self.imageView.image = UIImage(data: businessImageData)
            } else {
                loading = true
                business?.startLoadingImage({ (image, error) -> Void in
                    if (error == "Business download error") {
                        self.loading = false
                        self.imageView.backgroundColor = UIColor.redColor()
                    } else {
                        self.loading = error != nil
                        self.imageView.image = image
                    }
                    
                })
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.imageView.image = nil

    }
}
