//
//  DUALog.h
//  DUALive
//
//  Created by Mengmin Duan on 2017/5/16.
//  Copyright © 2017年 Mengmin Duan. All rights reserved.
//

//#ifndef __OPTIMIZE__
//#define DUALog(...) NSLog((@"[File:%s]" "[Function:%s]" "[Line:%d]" format), __FILE__, __FUNCTION__, __LINE__, ##__VA_ARGS__);
//#else
//#define DLog(...)
//#endif

#ifdef DEBUG
#define DUALog(format, ...) NSLog((@"[Function:%s  Line:%d]" format), __FUNCTION__, __LINE__, ##__VA_ARGS__);
#define DUADetailLog(format, ...) NSLog((@"[File:%s]" "[Function:%s]" "[Line:%d]" format), __FILE__, __FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#define DUALog(...);
#define DUADetailLog(...);
#endif
