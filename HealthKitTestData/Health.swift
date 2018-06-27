//
//  Health.swift
//  HealthKitTestData
//
//  Created by Ricky Kirkendall on 6/25/18.
//  Copyright © 2018 Ricky Kirkendall. All rights reserved.
//

import Foundation
import HealthKit
import SwiftDate
class Health {
    
    let healthStore = HKHealthStore()
    let hkTypes = HKObjectTypes()    
    func permission(){
        for ho in hkTypes.writables {
            print(ho.identifier)
        }
        healthStore.requestAuthorization(toShare: hkTypes.writables, read: hkTypes.readables) { (success, error) in
            if !success {
                // Handle the error here.
            }
        }
        
    }
    
    func getMostRecentSample(for sampleType: HKSampleType,
                             completion: @escaping (HKQuantitySample?, Error?) -> Swift.Void) {
        
        //1. Use HKQuery to load the most recent samples.
        let mostRecentPredicate = HKQuery.predicateForSamples(withStart: Date.distantPast,
                                                              end: Date(),
                                                              options: .strictEndDate)
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate,
                                              ascending: false)
        
        let limit = 1
        
        let sampleQuery = HKSampleQuery(sampleType: sampleType,
                                        predicate: mostRecentPredicate,
                                        limit: limit,
                                        sortDescriptors: [sortDescriptor]) { (query, samples, error) in
                                            
                                            //2. Always dispatch to the main thread when complete.
                                            DispatchQueue.main.async {
                                                
                                                guard let samples = samples,
                                                    let mostRecentSample = samples.first as? HKQuantitySample else {
                                                        
                                                        completion(nil, error)
                                                        return
                                                }
                                                
                                                completion(mostRecentSample, nil)
                                            }
        }
        
        HKHealthStore().execute(sampleQuery)
    }
    
    func writeData(){
        //1.  Make sure the body mass type exists
        guard let bodyMassIndexType = HKQuantityType.quantityType(forIdentifier: .bodyMassIndex) else {
            fatalError("Body Mass Index Type is no longer available in HealthKit")
        }
        
        //2.  Use the Count HKUnit to create a body mass quantity
        let bodyMassQuantity = HKQuantity(unit: HKUnit.count(),
                                          doubleValue: 21.5)
        
        
        let bodyMassIndexSample = HKQuantitySample(type: bodyMassIndexType,
                                                   quantity: bodyMassQuantity,
                                                   start: Date(),
                                                   end: Date())
        
        //3.  Save the same to HealthKit
        HKHealthStore().save(bodyMassIndexSample) { (success, error) in
            
            if let error = error {
                print("Error Saving BMI Sample: \(error.localizedDescription)")
            } else {
                print("Successfully saved BMI Sample")
            }
        }
    }
    
    func writeDataSince(since:Date, quantityTypeMap:[HKQuantityType:HKUnit]){
        var iterdate = since
        
        while iterdate < Date() {
            // Add samples for day
            for hkObjType in hkTypes.writables{
                if hkObjType.isKind(of: HKQuantityType.self){
                    guard let quantType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier(rawValue: hkObjType.identifier)) else {
                        fatalError("Quantity could not be set")
                    }
                    
                    var unit: HKUnit
                    if quantityTypeMap[quantType] != nil{
                        unit = quantityTypeMap[quantType]!
                    }else if quantType.compatibleUnit() != nil{
                        unit = quantType.compatibleUnit()!
                    }else{
                        fatalError("Compatible HKUnit not found for \(quantType.identifier)")
                    }
                    
                    let rand = Double(arc4random_uniform(100)+1)
                    let quantity = HKQuantity(unit: unit, doubleValue: rand)
                    
                    var sample : HKQuantitySample
                        
                    if quantType.identifier == "HKQuantityTypeIdentifierInsulinDelivery"{
                        sample = HKQuantitySample(type: quantType, quantity: quantity, start: iterdate, end: iterdate, metadata: [HKMetadataKeyInsulinDeliveryReason: NSNumber(integerLiteral: HKInsulinDeliveryReason.basal.rawValue)])
                    }else{
                        sample = HKQuantitySample(type: quantType,
                                         quantity: quantity,
                                         start: iterdate,
                                         end: iterdate)
                    }                                            
                    print(quantType.identifier)
                    
                    
                    healthStore.save(sample) { (success, error) in                        
                        if let error = error {
                            print("Error Saving sample: \(error.localizedDescription)")
                        } else {
                            print("Successfully saved sample")
                        }
                    }
                }
            }
            
            iterdate = iterdate + 1.day
        }
    }
    
    func writeDataSince(since:Date){
        
        healthStore.preferredUnits(for: hkTypes.writables as! Set<HKQuantityType>) { (quantityTypeMap, error) in
            self.writeDataSince(since: since, quantityTypeMap: quantityTypeMap)
        }
        
    }
    
    
    
}
