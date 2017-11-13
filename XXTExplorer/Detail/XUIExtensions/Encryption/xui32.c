//
//  xui32.c
//  XUIModel32
//
//  Created by Zheng on 2017/11/12.
//  Copyright © 2017年 Zheng. All rights reserved.
//

#include "stdio.h"
#include "stdlib.h"
#include "string.h"
#include "assert.h"
#include "xxtea.h"
#include "crc.h"
#include "xui32.h"

#define MIN(a,b) (a) < (b) ? (a) : (b)

void arc4random_buf_safe(void *buf, size_t nbytes) {
    arc4random_buf(buf, nbytes);
    unsigned char *buffer = buf;
    for (size_t i = 0; i < nbytes; i++) {
        if (*(buffer + i) == 0x0) {
            *(buffer + i) = 0xFF;
        }
    }
}

xui_32 *XUICreateWithData(const void *data, uint32_t length)
{
    assert(data);
    
    // crc init
    crcInit();
    
    xui_32 *xui = malloc(sizeof(xui_32));
    assert(xui);
    
    // magic
    xui->header.magic[0] = 0xe7;
    xui->header.magic[1] = 0x58; // X
    xui->header.magic[2] = 0x55; // U
    xui->header.magic[3] = 0x49; // I
    
    if (0 == memcmp(xui, data, sizeof(xui->header.magic))) {
        
        // already encrypted, load it
        
        // load header
        memcpy(xui, data, sizeof(xui_hdr_32));
        
        // check version
        if (xui->header.version > kXUIModelFormatVersion) {
            free(xui);
            return NULL;
        }
        
        // copy data
        uint32_t data_len = length - (sizeof(xui_hdr_32));
        void *out_data = malloc(data_len);
        assert(out_data);
        memcpy(out_data, data + sizeof(xui_hdr_32), data_len);
        
        // check hash
        crc data_hash = crcFast(out_data, data_len);
        if (data_hash != xui->header.data_hash) {
            free(out_data);
            free(xui);
            return NULL;
        }
        
        xui->data = out_data;
        return xui;
        
    } else {
        
        // version and flag
        xui->header.version = kXUIModelFormatVersion;
        xui->header.flag = 0xFF;
        
        uint32_t len = 0; // finished raw length
        uint32_t total = length; // total raw length
        uint32_t data_len = 0; // finished out length
        
        void *out_data = malloc(sizeof(xui_block_hdr_32)); // out data
        assert(out_data);
        
        while (len < total) {
            
            // block header
            xui_block_hdr_32 *block_hdr = malloc(sizeof(xui_block_hdr_32));
            assert(block_hdr);
            
            block_hdr->block_len = 0;
            
            // rand
            uint8_t rand[sizeof(block_hdr->rand)];
            memset(rand, 0xFF, sizeof(block_hdr->rand));
            arc4random_buf_safe(rand, sizeof(block_hdr->rand));
            memcpy(block_hdr->rand, rand, sizeof(block_hdr->rand));
            
            uint32_t enc_len = MIN(kXUIModelBlockLength, length - len);
            
            // crc hash
            crc block_hash = crcFast(data + len, (int)enc_len);
            block_hdr->block_hash = block_hash;
            
            // encrypt raw block
            size_t enc_out_len;
            void *enc_data = xxtea_encrypt(data + len, enc_len, rand, &enc_out_len);
            assert(enc_data);
            block_hdr->block_len += enc_out_len;
            len += enc_len;
            
            // realloc memory
            uint32_t new_len = data_len + sizeof(xui_block_hdr_32);
            new_len += enc_out_len;
            out_data = realloc(out_data, new_len);
            
            // write block header
            memcpy(out_data + data_len, block_hdr, sizeof(xui_block_hdr_32));
            data_len += sizeof(xui_block_hdr_32);
            
            // write block data
            memcpy(out_data + data_len, enc_data, enc_out_len);
            data_len += enc_out_len;
            
            // free memory
            free(enc_data);
            free(block_hdr);
            
        }
        
        crc data_hash = crcFast(out_data, (int)data_len);
        xui->header.data_hash = data_hash;
        xui->header.data_len = data_len;
        if (data_len == 0) {
            xui->data = NULL;
            free(out_data);
        } else {
            xui->data = out_data;
        }
        
        return xui;
    }
    
}

int XUIWriteToFile(const char *path, xui_32 *xui) {
    assert(xui);
    assert(xui->data);
    FILE *fp = fopen(path, "wb");
    if (!fp) return -1;
    fwrite(xui, sizeof(xui_hdr_32), 1, fp);
    fwrite(xui->data, xui->header.data_len, 1, fp);
    return fclose(fp);
}

void XUIRelease(xui_32 *xui) {
    assert(xui);
    if (xui->data)
    { free(xui->data); xui->data = NULL; }
    free(xui);
}

void XUICopyRawData(xui_32 *xui, const void **ptr, uint32_t *total) {
    assert(xui);
    assert(ptr);
    assert(total);
    
    uint32_t len = 0;
    uint32_t out_len = 0;
    
    void *read_data = malloc(kXUIModelBlockLength);
    assert(read_data);
    
    xui_block_hdr_32 block_header;
    while (len < xui->header.data_len) {
        
        // read block header
        memcpy(&block_header, xui->data + len, sizeof(xui_block_hdr_32));
        len += sizeof(xui_block_hdr_32);
        
        // decrypt block
        size_t dec_out_len;
        void *dec_data = xxtea_decrypt(xui->data + len, block_header.block_len, block_header.rand, &dec_out_len);
        if (!dec_data) {
            goto clean2;
        }
        len += block_header.block_len;
        
        // check hash
        crc block_hash = crcFast(dec_data, (int)dec_out_len);
        if (block_hash != block_header.block_hash) {
            free(dec_data);
            goto clean2;
        }
        
        // realloc memoty
        uint32_t new_len = out_len + (uint32_t)dec_out_len;
        read_data = realloc(read_data, new_len);
        
        // copy raw data
        memcpy(read_data + out_len, dec_data, dec_out_len);
        out_len += dec_out_len;
        
        free(dec_data);
    }
    
    *ptr = read_data;
    *total = out_len;
    
    return;
    
clean2:
    free(read_data);
    
}

xui_32 *XUICreateWithContentsOfFile(const char *path) {
    FILE *pTest = fopen(path, "rb");
    assert(pTest);
    
    fseek(pTest, 0, SEEK_END);
    size_t lSize = ftell(pTest);
    rewind(pTest);
    
    void *buffer = malloc(lSize);
    assert(buffer);
    fread(buffer, 1, lSize, pTest);
    
    fclose(pTest);
    
    xui_32 *obj = XUICreateWithData(buffer, (uint32_t)lSize);
    free(buffer);
    
    return obj;
}
