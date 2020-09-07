//
//  BBlock+CoreDataProperties.swift
//  
//
//  Created by matuilab on 2020/09/07.
//
//

import Foundation
import CoreData


extension BBlock {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BBlock> {
        return NSFetchRequest<BBlock>(entityName: "BBlock")
    }

    @NSManaged public var angle: Int16
    @NSManaged public var code: Int32
    @NSManaged public var id: Int16
    @NSManaged public var message: String?
    @NSManaged public var messagecategory: String?
    @NSManaged public var mp3: String?
    @NSManaged public var reading: String?

}
