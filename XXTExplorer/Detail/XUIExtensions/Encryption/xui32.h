//
//  xui32.h
//  XUIModel32
//
//  Created by Zheng on 13/11/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#ifndef xui32_h
#define xui32_h

static uint8_t const kXUIModelFormatVersion = 0xe0;
static uint32_t const kXUIModelBlockLength = 4096;
struct xui_hdr_32 {
    uint8_t magic[4]; // 4
    uint8_t version; // 1
    uint8_t flag; // 1
    uint16_t data_hash; // 2, the hash of data
    uint32_t data_len; // 4
};
struct xui_32 {
    struct xui_hdr_32 header;
    void *data;
};
struct xui_block_hdr_32 {
    uint16_t block_hash; // 2, the hash of raw block data
    uint8_t rand[16]; // 16
    uint32_t block_len; // 4
};

typedef struct xui_32 xui_32;
typedef struct xui_hdr_32 xui_hdr_32;
typedef struct xui_block_hdr_32 xui_block_hdr_32;

xui_32 *XUICreateWithData(const void *data, uint32_t length);
xui_32 *XUICreateWithContentsOfFile(const char *path);

int XUIWriteToFile(const char *path, xui_32 *xui);
void XUICopyRawData(xui_32 *xui, const void **ptr, uint32_t *total);

void XUIRelease(xui_32 *xui);

#endif /* xui32_h */
