//
//  TrustAnchor.h
//  Moonshot
//
//  Created by Elena Jakjoska on 12/29/17.
//

#import <Foundation/Foundation.h>

@interface TrustAnchor : NSObject

@property (nonatomic, strong) NSString *serverCertificate;
@property (nonatomic, strong) NSString *caCertificate;
@property (nonatomic, strong) NSString *subject;
@property (nonatomic, strong) NSString *subjectAlt;

@end
