#import "DSPColor.h"
#import "DSPHTTPTransactionDetailController.h"
#import "DSPNetworkCurlLogger.h"
#import "DSPNetworkRecorder.h"
#import "DSPNetworkTransaction.h"
#import "DSPWebViewController.h"
#import "DSPImagePreviewViewController.h"
#import "DSPMultilineTableViewCell.h"
#import "DSPUtility.h"
#import "DSPManager+Private.h"
#import "DSPTableView.h"
#import "UIBarButtonItem+DSP.h"
#import "NSDateFormatter+DSP.h"

typedef UIViewController *(^DSPNetworkDetailRowSelectionFuture)(void);

@interface DSPNetworkDetailRow : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *detailText;
@property (nonatomic, copy) DSPNetworkDetailRowSelectionFuture selectionFuture;
@end

@implementation DSPNetworkDetailRow
@end

@interface DSPNetworkDetailSection : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSArray<DSPNetworkDetailRow *> *rows;
@end

@implementation DSPNetworkDetailSection
@end

@interface DSPHTTPTransactionDetailController ()

@property (nonatomic, readonly) DSPHTTPTransaction *transaction;
@property (nonatomic, copy) NSArray<DSPNetworkDetailSection *> *sections;

@end

@implementation DSPHTTPTransactionDetailController

+ (instancetype)withTransaction:(DSPHTTPTransaction *)transaction {
    DSPHTTPTransactionDetailController *controller = [self new];
    controller.transaction = transaction;
    return controller;
}

- (instancetype)initWithStyle:(UITableViewStyle)style {
    // Force grouped style
    return [super initWithStyle:UITableViewStyleGrouped];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [NSNotificationCenter.defaultCenter addObserver:self
        selector:@selector(handleTransactionUpdatedNotification:)
        name:kDSPNetworkRecorderTransactionUpdatedNotification
        object:nil
    ];
    self.toolbarItems = @[
        UIBarButtonItem.dsp_dspibleSpace,
        [UIBarButtonItem
            dsp_itemWithTitle:@"Copy curl"
            target:self
            action:@selector(copyButtonPressed:)
        ]
    ];
    
    [self.tableView registerClass:[DSPMultilineTableViewCell class] forCellReuseIdentifier:kDSPMultilineCell];
}

- (void)setTransaction:(DSPHTTPTransaction *)transaction {
    if (![_transaction isEqual:transaction]) {
        _transaction = transaction;
        self.title = [transaction.request.URL lastPathComponent];
        [self rebuildTableSections];
    }
}

- (void)setSections:(NSArray<DSPNetworkDetailSection *> *)sections {
    if (![_sections isEqual:sections]) {
        _sections = [sections copy];
        [self.tableView reloadData];
    }
}

- (void)rebuildTableSections {
    NSMutableArray<DSPNetworkDetailSection *> *sections = [NSMutableArray new];

    DSPNetworkDetailSection *generalSection = [[self class] generalSectionForTransaction:self.transaction];
    if (generalSection.rows.count > 0) {
        [sections addObject:generalSection];
    }
    DSPNetworkDetailSection *requestHeadersSection = [[self class] requestHeadersSectionForTransaction:self.transaction];
    if (requestHeadersSection.rows.count > 0) {
        [sections addObject:requestHeadersSection];
    }
    DSPNetworkDetailSection *queryParametersSection = [[self class] queryParametersSectionForTransaction:self.transaction];
    if (queryParametersSection.rows.count > 0) {
        [sections addObject:queryParametersSection];
    }
    DSPNetworkDetailSection *postBodySection = [[self class] postBodySectionForTransaction:self.transaction];
    if (postBodySection.rows.count > 0) {
        [sections addObject:postBodySection];
    }
    DSPNetworkDetailSection *responseHeadersSection = [[self class] responseHeadersSectionForTransaction:self.transaction];
    if (responseHeadersSection.rows.count > 0) {
        [sections addObject:responseHeadersSection];
    }

    self.sections = sections;
}

- (void)handleTransactionUpdatedNotification:(NSNotification *)notification {
    DSPNetworkTransaction *transaction = [[notification userInfo] objectForKey:kDSPNetworkRecorderUserInfoTransactionKey];
    if (transaction == self.transaction) {
        [self rebuildTableSections];
    }
}

- (void)copyButtonPressed:(id)sender {
    [UIPasteboard.generalPasteboard setString:[DSPNetworkCurlLogger curlCommandString:_transaction.request]];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    DSPNetworkDetailSection *sectionModel = self.sections[section];
    return sectionModel.rows.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    DSPNetworkDetailSection *sectionModel = self.sections[section];
    return sectionModel.title;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    DSPMultilineTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kDSPMultilineCell forIndexPath:indexPath];

    DSPNetworkDetailRow *rowModel = [self rowModelAtIndexPath:indexPath];

    cell.textLabel.attributedText = [[self class] attributedTextForRow:rowModel];
    cell.accessoryType = rowModel.selectionFuture ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
    cell.selectionStyle = rowModel.selectionFuture ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    DSPNetworkDetailRow *rowModel = [self rowModelAtIndexPath:indexPath];

    UIViewController *viewController = nil;
    if (rowModel.selectionFuture) {
        viewController = rowModel.selectionFuture();
    }

    if ([viewController isKindOfClass:UIAlertController.class]) {
        [self presentViewController:viewController animated:YES completion:nil];
    } else if (viewController) {
        [self.navigationController pushViewController:viewController animated:YES];
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    DSPNetworkDetailRow *row = [self rowModelAtIndexPath:indexPath];
    NSAttributedString *attributedText = [[self class] attributedTextForRow:row];
    BOOL showsAccessory = row.selectionFuture != nil;
    return [DSPMultilineTableViewCell
        preferredHeightWithAttributedText:attributedText
        maxWidth:tableView.bounds.size.width
        style:tableView.style
        showsAccessory:showsAccessory
    ];
}

- (NSArray<NSString *> *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return [NSArray dsp_forEachUpTo:self.sections.count map:^id(NSUInteger i) {
        return @"⦁";
    }];
}

- (DSPNetworkDetailRow *)rowModelAtIndexPath:(NSIndexPath *)indexPath {
    DSPNetworkDetailSection *sectionModel = self.sections[indexPath.section];
    return sectionModel.rows[indexPath.row];
}

#pragma mark - Cell Copying

- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    return action == @selector(copy:);
}

- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    if (action == @selector(copy:)) {
        DSPNetworkDetailRow *row = [self rowModelAtIndexPath:indexPath];
        UIPasteboard.generalPasteboard.string = row.detailText;
    }
}

- (UIContextMenuConfiguration *)tableView:(UITableView *)tableView contextMenuConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath point:(CGPoint)point __IOS_AVAILABLE(13.0) {
    return [UIContextMenuConfiguration
        configurationWithIdentifier:nil
        previewProvider:nil
        actionProvider:^UIMenu *(NSArray<UIMenuElement *> *suggestedActions) {
            UIAction *copy = [UIAction
                actionWithTitle:@"Copy"
                image:nil
                identifier:nil
                handler:^(__kindof UIAction *action) {
                    DSPNetworkDetailRow *row = [self rowModelAtIndexPath:indexPath];
                    UIPasteboard.generalPasteboard.string = row.detailText;
                }
            ];
            return [UIMenu
                menuWithTitle:@"" image:nil identifier:nil
                options:UIMenuOptionsDisplayInline
                children:@[copy]
            ];
        }
    ];
}

#pragma mark - View Configuration

+ (NSAttributedString *)attributedTextForRow:(DSPNetworkDetailRow *)row {
    NSDictionary<NSString *, id> *titleAttributes = @{ NSFontAttributeName : [UIFont fontWithName:@"HelveticaNeue-Medium" size:12.0],
                                                       NSForegroundColorAttributeName : [UIColor colorWithWhite:0.5 alpha:1.0] };
    NSDictionary<NSString *, id> *detailAttributes = @{ NSFontAttributeName : UIFont.dsp_defaultTableCellFont,
                                                        NSForegroundColorAttributeName : DSPColor.primaryTextColor };

    NSString *title = [NSString stringWithFormat:@"%@: ", row.title];
    NSString *detailText = row.detailText ?: @"";
    NSMutableAttributedString *attributedText = [NSMutableAttributedString new];
    [attributedText appendAttributedString:[[NSAttributedString alloc] initWithString:title attributes:titleAttributes]];
    [attributedText appendAttributedString:[[NSAttributedString alloc] initWithString:detailText attributes:detailAttributes]];

    return attributedText;
}

#pragma mark - Table Data Generation

+ (DSPNetworkDetailSection *)generalSectionForTransaction:(DSPHTTPTransaction *)transaction {
    NSMutableArray<DSPNetworkDetailRow *> *rows = [NSMutableArray new];

    DSPNetworkDetailRow *requestURLRow = [DSPNetworkDetailRow new];
    requestURLRow.title = @"Request URL";
    NSURL *url = transaction.request.URL;
    requestURLRow.detailText = url.absoluteString;
    requestURLRow.selectionFuture = ^{
        UIViewController *urlWebViewController = [[DSPWebViewController alloc] initWithURL:url];
        urlWebViewController.title = url.absoluteString;
        return urlWebViewController;
    };
    [rows addObject:requestURLRow];

    DSPNetworkDetailRow *requestMethodRow = [DSPNetworkDetailRow new];
    requestMethodRow.title = @"Request Method";
    requestMethodRow.detailText = transaction.request.HTTPMethod;
    [rows addObject:requestMethodRow];

    if (transaction.cachedRequestBody.length > 0) {
        DSPNetworkDetailRow *postBodySizeRow = [DSPNetworkDetailRow new];
        postBodySizeRow.title = @"Request Body Size";
        postBodySizeRow.detailText = [NSByteCountFormatter stringFromByteCount:transaction.cachedRequestBody.length countStyle:NSByteCountFormatterCountStyleBinary];
        [rows addObject:postBodySizeRow];

        DSPNetworkDetailRow *postBodyRow = [DSPNetworkDetailRow new];
        postBodyRow.title = @"Request Body";
        postBodyRow.detailText = @"tap to view";
        postBodyRow.selectionFuture = ^UIViewController * () {
            // Show the body if we can
            NSString *contentType = [transaction.request valueForHTTPHeaderField:@"Content-Type"];
            NSData *body = [self postBodyDataForTransaction:transaction];
            UIViewController *detailViewController = [self detailViewControllerForMIMEType:contentType data:body];
            if (detailViewController) {
                detailViewController.title = @"Request Body";
                return detailViewController;
            }

            // We can't show the body, alert user
            return [DSPAlert makeAlert:^(DSPAlert *make) {
                if (!body) {
                    make.title(@"Empty HTTP Body");
                } else {
                    make.title(@"Can't View HTTP Body Data");
                    make.message(@"DSP does not have a viewer for request body data with MIME type: ");
                }
                make.message(contentType);
                make.button(@"Dismiss").cancelStyle();
            }];
        };

        [rows addObject:postBodyRow];
    }

    NSString *statusCodeString = [DSPUtility statusCodeStringFromURLResponse:transaction.response];
    if (statusCodeString.length > 0) {
        DSPNetworkDetailRow *statusCodeRow = [DSPNetworkDetailRow new];
        statusCodeRow.title = @"Status Code";
        statusCodeRow.detailText = statusCodeString;
        [rows addObject:statusCodeRow];
    }

    if (transaction.error) {
        DSPNetworkDetailRow *errorRow = [DSPNetworkDetailRow new];
        errorRow.title = @"Error";
        errorRow.detailText = transaction.error.localizedDescription;
        [rows addObject:errorRow];
    }

    DSPNetworkDetailRow *responseBodyRow = [DSPNetworkDetailRow new];
    responseBodyRow.title = @"Response Body";
    NSData *responseData = [DSPNetworkRecorder.defaultRecorder cachedResponseBodyForTransaction:transaction];
    if (responseData.length > 0) {
        responseBodyRow.detailText = @"tap to view";

        // Avoid a long lived strong reference to the response data in case we need to purge it from the cache.
        weakify(responseData)
        responseBodyRow.selectionFuture = ^UIViewController *() { strongify(responseData)

            // Show the response if we can
            NSString *contentType = transaction.response.MIMEType;
            if (responseData) {
                UIViewController *bodyDetails = [self detailViewControllerForMIMEType:contentType data:responseData];
                if (bodyDetails) {
                    bodyDetails.title = @"Response";
                    return bodyDetails;
                }
            }

            // We can't show the response, alert user
            return [DSPAlert makeAlert:^(DSPAlert *make) {
                make.title(@"Unable to View Response");
                if (responseData) {
                    make.message(@"No viewer content type: ").message(contentType);
                } else {
                    make.message(@"The response has been purged from the cache");
                }
                make.button(@"OK").cancelStyle();
            }];
        };
    } else {
        BOOL emptyResponse = transaction.receivedDataLength == 0;
        responseBodyRow.detailText = emptyResponse ? @"empty" : @"not in cache";
    }

    [rows addObject:responseBodyRow];

    DSPNetworkDetailRow *responseSizeRow = [DSPNetworkDetailRow new];
    responseSizeRow.title = @"Response Size";
    responseSizeRow.detailText = [NSByteCountFormatter stringFromByteCount:transaction.receivedDataLength countStyle:NSByteCountFormatterCountStyleBinary];
    [rows addObject:responseSizeRow];

    DSPNetworkDetailRow *mimeTypeRow = [DSPNetworkDetailRow new];
    mimeTypeRow.title = @"MIME Type";
    mimeTypeRow.detailText = transaction.response.MIMEType;
    [rows addObject:mimeTypeRow];

    DSPNetworkDetailRow *mechanismRow = [DSPNetworkDetailRow new];
    mechanismRow.title = @"Mechanism";
    mechanismRow.detailText = transaction.requestMechanism;
    [rows addObject:mechanismRow];

    DSPNetworkDetailRow *localStartTimeRow = [DSPNetworkDetailRow new];
    localStartTimeRow.title = [NSString stringWithFormat:@"Start Time (%@)", [NSTimeZone.localTimeZone abbreviationForDate:transaction.startTime]];
    localStartTimeRow.detailText = [NSDateFormatter dsp_stringFrom:transaction.startTime format:DSPDateFormatVerbose];
    [rows addObject:localStartTimeRow];

    DSPNetworkDetailRow *utcStartTimeRow = [DSPNetworkDetailRow new];
    utcStartTimeRow.title = @"Start Time (UTC)";
    utcStartTimeRow.detailText = [NSDateFormatter dsp_stringFrom:transaction.startTime format:DSPDateFormatVerbose];
    [rows addObject:utcStartTimeRow];

    DSPNetworkDetailRow *unixStartTime = [DSPNetworkDetailRow new];
    unixStartTime.title = @"Unix Start Time";
    unixStartTime.detailText = [NSString stringWithFormat:@"%f", [transaction.startTime timeIntervalSince1970]];
    [rows addObject:unixStartTime];

    DSPNetworkDetailRow *durationRow = [DSPNetworkDetailRow new];
    durationRow.title = @"Total Duration";
    durationRow.detailText = [DSPUtility stringFromRequestDuration:transaction.duration];
    [rows addObject:durationRow];

    DSPNetworkDetailRow *latencyRow = [DSPNetworkDetailRow new];
    latencyRow.title = @"Latency";
    latencyRow.detailText = [DSPUtility stringFromRequestDuration:transaction.latency];
    [rows addObject:latencyRow];

    DSPNetworkDetailSection *generalSection = [DSPNetworkDetailSection new];
    generalSection.title = @"General";
    generalSection.rows = rows;

    return generalSection;
}

+ (DSPNetworkDetailSection *)requestHeadersSectionForTransaction:(DSPHTTPTransaction *)transaction {
    DSPNetworkDetailSection *requestHeadersSection = [DSPNetworkDetailSection new];
    requestHeadersSection.title = @"Request Headers";
    requestHeadersSection.rows = [self networkDetailRowsFromDictionary:transaction.request.allHTTPHeaderFields];

    return requestHeadersSection;
}

+ (DSPNetworkDetailSection *)postBodySectionForTransaction:(DSPHTTPTransaction *)transaction {
    DSPNetworkDetailSection *postBodySection = [DSPNetworkDetailSection new];
    postBodySection.title = @"Request Body Parameters";
    if (transaction.cachedRequestBody.length > 0) {
        NSString *contentType = [transaction.request valueForHTTPHeaderField:@"Content-Type"];
        if ([contentType hasPrefix:@"application/x-www-form-urlencoded"]) {
            NSData *body = [self postBodyDataForTransaction:transaction];
            NSString *bodyString = [[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding];
            postBodySection.rows = [self networkDetailRowsFromQueryItems:[DSPUtility itemsFromQueryString:bodyString]];
        }
    }
    return postBodySection;
}

+ (DSPNetworkDetailSection *)queryParametersSectionForTransaction:(DSPHTTPTransaction *)transaction {
    NSArray<NSURLQueryItem *> *queries = [DSPUtility itemsFromQueryString:transaction.request.URL.query];
    DSPNetworkDetailSection *querySection = [DSPNetworkDetailSection new];
    querySection.title = @"Query Parameters";
    querySection.rows = [self networkDetailRowsFromQueryItems:queries];

    return querySection;
}

+ (DSPNetworkDetailSection *)responseHeadersSectionForTransaction:(DSPHTTPTransaction *)transaction {
    DSPNetworkDetailSection *responseHeadersSection = [DSPNetworkDetailSection new];
    responseHeadersSection.title = @"Response Headers";
    if ([transaction.response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)transaction.response;
        responseHeadersSection.rows = [self networkDetailRowsFromDictionary:httpResponse.allHeaderFields];
    }
    return responseHeadersSection;
}

+ (NSArray<DSPNetworkDetailRow *> *)networkDetailRowsFromDictionary:(NSDictionary<NSString *, id> *)dictionary {
    NSMutableArray<DSPNetworkDetailRow *> *rows = [NSMutableArray new];
    NSArray<NSString *> *sortedKeys = [dictionary.allKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    
    for (NSString *key in sortedKeys) {
        id value = dictionary[key];
        DSPNetworkDetailRow *row = [DSPNetworkDetailRow new];
        row.title = key;
        row.detailText = [value description];
        [rows addObject:row];
    }

    return rows.copy;
}

+ (NSArray<DSPNetworkDetailRow *> *)networkDetailRowsFromQueryItems:(NSArray<NSURLQueryItem *> *)items {
    // Sort the items by name
    items = [items sortedArrayUsingComparator:^NSComparisonResult(NSURLQueryItem *item1, NSURLQueryItem *item2) {
        return [item1.name caseInsensitiveCompare:item2.name];
    }];

    NSMutableArray<DSPNetworkDetailRow *> *rows = [NSMutableArray new];
    for (NSURLQueryItem *item in items) {
        DSPNetworkDetailRow *row = [DSPNetworkDetailRow new];
        row.title = item.name;
        row.detailText = item.value;
        [rows addObject:row];
    }

    return [rows copy];
}

+ (UIViewController *)detailViewControllerForMIMEType:(NSString *)mimeType data:(NSData *)data {
    if (!data) {
        return nil; // An alert will be presented in place of this screen
    }
    
    DSPCustomContentViewerFuture makeCustomViewer = DSPManager.sharedManager.customContentTypeViewers[mimeType.lowercaseString];

    if (makeCustomViewer) {
        UIViewController *viewer = makeCustomViewer(data);

        if (viewer) {
            return viewer;
        }
    }

    // FIXME (RKO): Don't rely on UTF8 string encoding
    UIViewController *detailViewController = nil;
    if ([DSPUtility isValidJSONData:data]) {
        NSString *prettyJSON = [DSPUtility prettyJSONStringFromData:data];
        if (prettyJSON.length > 0) {
            detailViewController = [[DSPWebViewController alloc] initWithText:prettyJSON];
        }
    } else if ([mimeType hasPrefix:@"image/"]) {
        UIImage *image = [UIImage imageWithData:data];
        detailViewController = [DSPImagePreviewViewController forImage:image];
    } else if ([mimeType isEqual:@"application/x-plist"]) {
        id propertyList = [NSPropertyListSerialization propertyListWithData:data options:0 format:NULL error:NULL];
        detailViewController = [[DSPWebViewController alloc] initWithText:[propertyList description]];
    }

    // Fall back to trying to show the response as text
    if (!detailViewController) {
        NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (text.length > 0) {
            detailViewController = [[DSPWebViewController alloc] initWithText:text];
        }
    }
    return detailViewController;
}

+ (NSData *)postBodyDataForTransaction:(DSPHTTPTransaction *)transaction {
    NSData *bodyData = transaction.cachedRequestBody;
    if (bodyData.length > 0 && [DSPUtility hasCompressedContentEncoding:transaction.request]) {
        bodyData = [DSPUtility inflatedDataFromCompressedData:bodyData];
    }
    return bodyData;
}

@end
