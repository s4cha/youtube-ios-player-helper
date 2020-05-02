//
//  YTPlayerError.swift
//  YouTubeiOSPlayerHelper
//
//  Created by Sacha DSO on 02/05/2020.
//  Copyright © 2020 YouTube Developer Relations. All rights reserved.
//

// Copyright 2014 Google Inc. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation

/** These enums represent error codes thrown by the player. */
public enum YTPlayerError {
    case invalidParam
    case html5Error
    case videoNotFound // Functionally equivalent error codes 100 and
    // 105 have been collapsed into |kYTPlayerErrorVideoNotFound|.
    case notEmbeddable // Functionally equivalent error codes 101 and
    // 150 have been collapsed into |kYTPlayerErrorNotEmbeddable|.
    case unknown
}
