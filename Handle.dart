/*

  Copyright (C) 2012 John McCutchan <john@johnmccutchan.com>
  
  This software is provided 'as-is', without any express or implied
  warranty.  In no event will the authors be held liable for any damages
  arising from the use of this software.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely, subject to the following restrictions:

  1. The origin of this software must not be misrepresented; you must not
     claim that you wrote the original software. If you use this software
     in a product, an acknowledgment in the product documentation would be
     appreciated but is not required.
  2. Altered source versions must be plainly marked as such, and must not be
     misrepresented as being the original software.
  3. This notice may not be removed or altered from any source distribution.

*/

class Handle {
  // Handle fits in 32-bits
  // 20 bits for index (1MB of handles)
  static final int IndexMask = 0xFFFFF;
  static final int IndexShift = 0;
  // 4 bits for a serial number
  static final int SerialMask = 0xF;
  static final int SerialShift = 20;
  // 4 bits for a type
  static final int TypeMask = 0xF;
  static final int TypeShift = 24;
  // 4 bits for a status
  static final int StatusMask = 0xF;
  static final int StatusShift = 28;
  
  static final int StatusUsed = 0x1;
  static final int StatusFreeList = 0x2;

  static final int BadHandle = 0xFFFFFFFF;
  
  static int getStatus(int handle) {
    return (handle >> StatusShift) & StatusMask;
  }
  
  static int getType(int handle) {
    return (handle >> TypeShift) & TypeMask;
  }
  
  static int getSerial(int handle) {
    return (handle >> SerialShift) & SerialMask;
  }
  
  static int getIndex(int handle) {
    return (handle >> IndexShift) & IndexMask;
  }
  
  static int nextSerial(int handle) {
    int index = getIndex(handle);
    int serial = getSerial(handle);
    int type = getType(handle);
    int status = getStatus(handle);
    
    serial = (serial+1) & SerialMask;
    if (serial == SerialMask) {
      // We skip over SerialMask
      // Currently that leaves about 15 serial numbers
      serial = 0;
    }
    return makeHandle(index, serial, type, status);
  }
  
  static int setType(int handle, int type) {
    int index = getIndex(handle);
    int serial = getSerial(handle);
    int status = getStatus(handle);
    return makeHandle(index, serial, type, status);
  }
  
  static int setIndex(int handle, int index) {
    int serial = getSerial(handle);
    int type = getType(handle);
    int status = getStatus(handle);
    return makeHandle(index, serial, type, status);
  }
  
  static int setStatusFlag(int handle, int flag) {
    int bit = flag << StatusShift;
    return handle|bit;
  }
  
  static int clearStatusFlag(int handle, int flag) {
    int bit = flag << StatusShift;
    handle &= ~bit;
    return handle;
  }
  
  static bool checkStatusFlag(int handle, int flag) {
    return (Handle.getStatus(handle) & flag) != 0;
  }
  
  static int makeHandle(int index, int serial, int type, int status) {
    index = index & IndexMask;
    index = index << IndexShift;
    serial = serial & SerialMask;
    serial = serial << SerialShift;
    type = type & TypeMask;
    type = type << TypeShift;
    status = status & StatusMask;
    status = status << StatusShift;
    return index|serial|type|status;
  }
  
  // A static handle has a serial of SerialMask
  static int makeStaticHandle(int index, int type, int status) {
    return makeHandle(index, SerialMask, type, status);
  }
  
  static bool isStaticHandle(int handle) {
    int serial = getSerial(handle);
    return serial == SerialMask;
  }
  
  // A next pointer has the status flag StatusFreeList
  static int makeNextPointer(int serial, int nextIndex) {
    return makeHandle(nextIndex, serial, 0, StatusFreeList);
  }
  
  static bool isNextPointer(int handle) {
    int status = getStatus(handle);
    return status == StatusFreeList;
  }
}