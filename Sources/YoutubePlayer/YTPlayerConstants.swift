//
//  YTPlayerConstants.swift
//  YouTubeiOSPlayerHelper
//
//  Created by Sacha DSO on 02/05/2020.
//  Copyright © 2020 YouTube Developer Relations. All rights reserved.
//

import Foundation

// These are instances of NSString because we get them from parsing a URL. It would be silly to
// convert these into an integer just to have to convert the URL query string value into an integer
// as well for the sake of doing a value comparison. A full list of response error codes can be
// found here:
//      https://developers.google.com/youtube/iframe_api_reference

let kYTPlayerStateUnstartedCode = "-1"
let kYTPlayerStateEndedCode = "0"
let kYTPlayerStatePlayingCode = "1"
let kYTPlayerStatePausedCode = "2"
let kYTPlayerStateBufferingCode = "3"
let kYTPlayerStateCuedCode = "5"
let kYTPlayerStateUnknownCode = "unknown"

// Constants representing playback quality.
let kYTPlaybackQualitySmallQuality = "small"
let kYTPlaybackQualityMediumQuality = "medium"
let kYTPlaybackQualityLargeQuality = "large"
let kYTPlaybackQualityHD720Quality = "hd720"
let kYTPlaybackQualityHD1080Quality = "hd1080"
let kYTPlaybackQualityHighResQuality = "highres"
let kYTPlaybackQualityAutoQuality = "auto"
let kYTPlaybackQualityDefaultQuality = "default"
let kYTPlaybackQualityUnknownQuality = "unknown"

// Constants representing YouTube player errors.
let kYTPlayerErrorInvalidParamErrorCode = "2"
let kYTPlayerErrorHTML5ErrorCode = "5"
let kYTPlayerErrorVideoNotFoundErrorCode = "100"
let kYTPlayerErrorNotEmbeddableErrorCode = "101"
let kYTPlayerErrorCannotFindVideoErrorCode = "105"
let kYTPlayerErrorSameAsNotEmbeddableErrorCode = "150"

// Constants representing player callbacks.
let kYTPlayerCallbackOnReady = "onReady"
let kYTPlayerCallbackOnStateChange = "onStateChange"
let kYTPlayerCallbackOnPlaybackQualityChange = "onPlaybackQualityChange"
let kYTPlayerCallbackOnError = "onError"
let kYTPlayerCallbackOnPlayTime = "onPlayTime"

let kYTPlayerCallbackOnYouTubeIframeAPIReady = "onYouTubeIframeAPIReady"
let kYTPlayerCallbackOnYouTubeIframeAPIFailedToLoad = "onYouTubeIframeAPIFailedToLoad"

let kYTPlayerEmbedUrlRegexPattern = "^http(s)://(www.)youtube.com/embed/(.*)$"
let kYTPlayerAdUrlRegexPattern = "^http(s)://pubads.g.doubleclick.net/pagead/conversion/"
let kYTPlayerOAuthRegexPattern = "^http(s)://accounts.google.com/o/oauth2/(.*)$"
let kYTPlayerStaticProxyRegexPattern = "^https://content.googleapis.com/static/proxy.html(.*)$"
let kYTPlayerSyndicationRegexPattern = "^https://tpc.googlesyndication.com/sodar/(.*).html$"

