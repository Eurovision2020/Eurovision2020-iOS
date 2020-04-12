//
//  Song.swift
//  Eurovision2020
//
//  Created by Sacha DSO on 12/04/2020.
//  Copyright © 2020 MarsacProductions. All rights reserved.
//

import Foundation

class Song {
    var identifier = ""
    var country: Country?
    var title = ""
    var number = 0
    var numberOfVotesGiven = 0
    
    func addVote() {
        numberOfVotesGiven = numberOfVotesGiven + 1
    }
    
    func removeVote() {
        numberOfVotesGiven = numberOfVotesGiven - 1
    }
}
