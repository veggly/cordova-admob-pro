// Alex Felipelli

//
//  CDVAdMobPlugin.m
//  TestAdMobCombo
//
//  Created by Xie Liming on 14-10-20.
//
//

#import <AdSupport/ASIdentifierManager.h>

#import <GoogleMobileAds/GoogleMobileAds.h>

#import <CoreLocation/CLLocation.h>

#import "CDVAdMobPlugin.h"
#import "AdMobMediation.h"

#define TEST_BANNER_ID           @"ca-app-pub-3940256099942544/2934735716"
#define TEST_INTERSTITIALID      @"ca-app-pub-3940256099942544/4411468910"
#define TEST_REWARDVIDEOID       @"ca-app-pub-3940256099942544/1712485313"

#define OPT_ADCOLONY        @"AdColony"
#define OPT_ADCOLONY        @"AdColony"
#define OPT_FLURRY          @"Flurry"
#define OPT_MMEDIA          @"mMedia"
#define OPT_INMOBI          @"InMobi"
#define OPT_FACEBOOK        @"Facebook"
#define OPT_MOBFOX          @"MobFox"
#define OPT_IAD             @"iAd"

#define OPT_GENDER          @"gender"
#define OPT_LOCATION        @"location"
#define OPT_FORCHILD        @"forChild"
#define OPT_CONTENTURL      @"contentURL"
#define OPT_CUSTOMTARGETING @"customTargeting"
#define OPT_EXCLUDE         @"exclude"

//@interface CDVAdMobPlugin()<GADBannerViewDelegate, GADInterstitialDelegate, GADRewardBasedVideoAdDelegate>
@interface CDVAdMobPlugin()<GADFullScreenContentDelegate, GADCustomEventInterstitialDelegate, GADCustomEventInterstitial>

@property (assign) GADAdSize adSize;
@property (nonatomic, retain) NSDictionary* adExtras;
@property (nonatomic, retain) NSMutableDictionary* mediations;

@property (nonatomic, retain) NSString* mGender;
@property (nonatomic, retain) NSArray* mLocation;
@property (nonatomic, retain) NSString* mForChild;
@property (nonatomic, retain) NSString* mContentURL;

@property (nonatomic, retain) NSDictionary* mCustomTargeting;
@property (nonatomic, retain) NSArray* mExclude;

@property (nonatomic, retain) NSString* rewardVideoAdId;
@property(nonatomic, strong) GADInterstitialAd* interstitial;

- (GADAdSize)__AdSizeFromString:(NSString *)str;
- (GADRequest*) __buildAdRequest:(BOOL)forBanner forDFP:(BOOL)fordfp;
- (NSString *) __getAdMobDeviceId;

@end

@implementation CDVAdMobPlugin

- (void)pluginInitialize
{
    [super pluginInitialize];
    
    self.adSize = [self __AdSizeFromString:@"SMART_BANNER"];
    self.mediations = [[NSMutableDictionary alloc] init];
    
    self.mGender = nil;
    self.mLocation = nil;
    self.mForChild = nil;
    self.mContentURL = nil;

    self.mCustomTargeting = nil;
    self.mExclude = nil;

    self.rewardVideoAdId = nil;
    
    [[GADMobileAds sharedInstance] startWithCompletionHandler:nil];
}

- (NSString*) __getProductShortName { return @"AdMob"; }

- (NSString*) __getTestBannerId {
    return TEST_BANNER_ID;
}
- (NSString*) __getTestInterstitialId {
    return TEST_INTERSTITIALID;
}
- (NSString*) __getTestRewardVideoId {
  return TEST_REWARDVIDEOID;
}

- (void) parseOptions:(NSDictionary *)options
{
    [super parseOptions:options];
    
    NSString* str = [options objectForKey:OPT_AD_SIZE];
    if(str) self.adSize = [self __AdSizeFromString:str];
    self.adExtras = [options objectForKey:OPT_AD_EXTRAS];
    if(self.mediations) {
        // TODO: if mediation need code in, add here
    }
    NSArray* arr = [options objectForKey:OPT_LOCATION];
    if(arr != nil) {
        self.mLocation = arr;
    }
    NSString* n = [options objectForKey:OPT_FORCHILD];
    if(n != nil) {
        self.mForChild = n;
    }
    str = [options objectForKey:OPT_CONTENTURL];
    if(str != nil){
        self.mContentURL = str;
    }
    str = [options objectForKey:OPT_GENDER];
    if(str != nil){
        self.mGender = str;
    }
    NSDictionary* dict = [options objectForKey:OPT_CUSTOMTARGETING];
    if(dict != nil) {
        self.mCustomTargeting = dict;
    }
    arr = [options objectForKey:OPT_EXCLUDE];
    if(arr != nil) {
        self.mExclude = arr;
    }
}

- (UIView*) __createAdView:(NSString*)adId {
    
    if(GADAdSizeEqualToSize(self.adSize, kGADAdSizeInvalid)) {
        self.adSize = GADAdSizeFromCGSize( CGSizeMake(self.adWidth, self.adHeight) );
    }
    if(GADAdSizeEqualToSize(self.adSize, kGADAdSizeInvalid)) {
        self.adSize = [self __isLandscape] ? kGADAdSizeSmartBannerLandscape : kGADAdSizeSmartBannerPortrait;
    }

    // safety check to avoid crash if adId is empty
    if(adId==nil || [adId length]==0) adId = TEST_BANNER_ID;

    GADBannerView* ad = nil;
    if(* [adId UTF8String] == '/') {
        ad = [[GADBannerView alloc] initWithAdSize:self.adSize];
    } else {
        ad = [[GADBannerView alloc] initWithAdSize:self.adSize];
    }
    
    ad.rootViewController = [self getViewController];
    ad.delegate = self;
    ad.adUnitID = adId;

    return ad;
}

- (GADRequest*) __buildAdRequest:(BOOL)forBanner forDFP:(BOOL)fordfp
{
    return nil;
}

- (GADAdSize)__AdSizeFromString:(NSString *)str
{
    if ([str isEqualToString:@"BANNER"]) {
        return kGADAdSizeBanner;
    } else if ([str isEqualToString:@"SMART_BANNER"]) {
        // Have to choose the right Smart Banner constant according to orientation.
        if([self __isLandscape]) {
            return kGADAdSizeSmartBannerLandscape;
        }
        else {
            return kGADAdSizeSmartBannerPortrait;
        }
    } else if ([str isEqualToString:@"MEDIUM_RECTANGLE"]) {
        return kGADAdSizeMediumRectangle;
    } else if ([str isEqualToString:@"FULL_BANNER"]) {
        return kGADAdSizeFullBanner;
    } else if ([str isEqualToString:@"LEADERBOARD"]) {
        return kGADAdSizeLeaderboard;
    } else if ([str isEqualToString:@"SKYSCRAPER"]) {
        return kGADAdSizeSkyscraper;
    } else if ([str isEqualToString:@"LARGE_BANNER"]) {
        return kGADAdSizeLargeBanner;
    } else {
        return kGADAdSizeInvalid;
    }
}

- (NSString *) __getAdMobDeviceId
{
    NSUUID* adid = [[ASIdentifierManager sharedManager] advertisingIdentifier];
    return [self md5:adid.UUIDString];
}

- (void) __showBanner:(int) position atX:(int)x atY:(int)y
{
}

- (int) __getAdViewWidth:(UIView*)view {
    return view.frame.size.width;
}

- (int) __getAdViewHeight:(UIView*)view {
    return view.frame.size.height;
}

- (void) __loadAdView:(UIView*)view {
}

- (void) __pauseAdView:(UIView*)view {
}

- (void) __resumeAdView:(UIView*)view {
}

- (void) __destroyAdView:(UIView*)view {
}

- (NSObject*) __createInterstitial:(NSString*)adId {
    self.interstitialReady = false;
    
    GADInterstitialAd* ad = nil;
    GADRequest *request = [GADRequest request];
      [GADInterstitialAd loadWithAdUnitID:adId
        //[GADInterstitialAd loadWithAdUnitID:@"ca-app-pub-3940256099942544/4411468910"
                                  request:request
                        completionHandler:^(GADInterstitialAd *ad, NSError *error) {
        if (error) {
          NSLog(@"Failed to load interstitial ad with error: %@", [error localizedDescription]);
          return;
        }
        self.interstitial = ad;
      }];
    return ad;
    
    /*
    // safety check to avoid crash if adId is empty
    if(adId==nil || [adId length]==0) adId = TEST_INTERSTITIALID;

    GADInterstitialAd* ad = nil;
    if(* [adId UTF8String] == '/') {
        ad = [[DFPInterstitial alloc] initWithAdUnitID:adId];
    } else {
        ad = [[GADInterstitial alloc] initWithAdUnitID:adId];
    }
    ad.delegate = self;
    
    */
    
    ;
}

- (void) __loadInterstitial:(NSObject*)interstitial {
    
    /*
    if([interstitial class] == [DFPInterstitial class]) {
        DFPInterstitial* ad = (DFPInterstitial*) interstitial;
        [ad loadRequest:[self __buildAdRequest:true forDFP:true]];

    } else if([interstitial class] == [GADInterstitial class]) {
        GADInterstitial* ad = (GADInterstitial*) interstitial;
        if(ad) {
            [ad loadRequest:[self __buildAdRequest:false forDFP:false]];
        }
    }
     */
}

- (void) __showInterstitial:(NSObject*)interstitial {

    
    if (self.interstitial) {
        //[self.interstitial presentFromRootViewController:self];
        [self.interstitial presentFromRootViewController:[self getViewController]];
        
      } else {
        NSLog(@"Ad wasn't ready");
      }
}

- (void) __destroyInterstitial:(NSObject*)interstitial {
}


#pragma mark GADBannerViewDelegate implementation

/**
 * document.addEventListener('onAdLoaded', function(data));
 * document.addEventListener('onAdFailLoad', function(data));
 * document.addEventListener('onAdPresent', function(data));
 * document.addEventListener('onAdDismiss', function(data));
 * document.addEventListener('onAdLeaveApp', function(data));
 */
- (void)adViewDidReceiveAd:(GADBannerView *)adView {
    if((! self.bannerVisible) && self.autoShowBanner) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self __showBanner:self.adPosition atX:self.posX atY:self.posY];
        });
    }
    [self fireAdEvent:EVENT_AD_LOADED withType:ADTYPE_BANNER];
}


- (void)adViewWillLeaveApplication:(GADBannerView *)adView {
    [self fireAdEvent:EVENT_AD_LEAVEAPP withType:ADTYPE_BANNER];
}

- (void)adViewWillPresentScreen:(GADBannerView *)adView {
    [self fireAdEvent:EVENT_AD_PRESENT withType:ADTYPE_BANNER];
}

- (void)adViewDidDismissScreen:(GADBannerView *)adView {
    [self fireAdEvent:EVENT_AD_DISMISS withType:ADTYPE_BANNER];
}

/**
 * document.addEventListener('onAdLoaded', function(data));
 * document.addEventListener('onAdFailLoad', function(data));
 * document.addEventListener('onAdPresent', function(data));
 * document.addEventListener('onAdDismiss', function(data));
 * document.addEventListener('onAdLeaveApp', function(data));
 */

/// Tells the delegate that the ad failed to present full screen content.
- (void)ad:(nonnull id<GADFullScreenPresentingAd>)ad
didFailToPresentFullScreenContentWithError:(nonnull NSError *)error {
    NSLog(@"Ad did fail to present full screen content.");
}

/// Tells the delegate that the ad presented full screen content.
- (void)adDidPresentFullScreenContent:(nonnull id<GADFullScreenPresentingAd>)ad {
    NSLog(@"Ad did present full screen content.");
}

/// Tells the delegate that the ad dismissed full screen content.
- (void)adDidDismissFullScreenContent:(nonnull id<GADFullScreenPresentingAd>)ad {
   NSLog(@"Ad did dismiss full screen content.");
}

/*
- (void)interstitial:(GADInterstitialAd *)ad didFailToReceiveAdWithError:(GADRequestError *)error {
    [self fireAdErrorEvent:EVENT_AD_FAILLOAD withCode:(int)error.code withMsg:[error localizedDescription] withType:ADTYPE_INTERSTITIAL];
}

- (void)interstitialDidReceiveAd:(GADInterstitial *)interstitial {
    self.interstitialReady = true;
    if (self.interstitial && self.autoShowInterstitial) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self __showInterstitial:self.interstitial];
        });
    }
    [self fireAdEvent:EVENT_AD_LOADED withType:ADTYPE_INTERSTITIAL];
}

- (void)interstitialWillPresentScreen:(GADInterstitial *)interstitial {
    [self fireAdEvent:EVENT_AD_PRESENT withType:ADTYPE_INTERSTITIAL];
}

- (void)interstitialDidDismissScreen:(GADInterstitial *)interstitial {
    [self fireAdEvent:EVENT_AD_DISMISS withType:ADTYPE_INTERSTITIAL];
    
    if(self.interstitial) {
        [self __destroyInterstitial:self.interstitial];
        self.interstitial = nil;
    }
}

- (void)interstitialWillLeaveApplication:(GADInterstitial *)ad {
    [self fireAdEvent:EVENT_AD_LEAVEAPP withType:ADTYPE_INTERSTITIAL];
}
*/


@end
