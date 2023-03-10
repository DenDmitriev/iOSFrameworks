//
//  GMSDeprecationMacros.h
//  Google Maps SDK for iOS
//
//  Copyright 2015 Google LLC
//
//  Usage of this SDK is subject to the Google Maps/Google Earth APIs Terms of
//  Service: https://developers.google.com/maps/terms
//

#ifndef IPHONE_MAPS_SDK_BASE_API_GMSDEPRECATIONMACROS_H_
#define IPHONE_MAPS_SDK_BASE_API_GMSDEPRECATIONMACROS_H_

/** Inside Google, this is defined in sdk.bzl. */
#ifndef __GMS_AVAILABLE_BUT_DEPRECATED
#define __GMS_AVAILABLE_BUT_DEPRECATED __deprecated
#endif

/** Inside Google, this is defined in sdk.bzl. */
#ifndef __GMS_AVAILABLE_BUT_DEPRECATED_MSG
#define __GMS_AVAILABLE_BUT_DEPRECATED_MSG(msg) __deprecated_msg(msg)
#endif

#endif
