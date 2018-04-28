function fileSize(byte) {
  var i = byte == 0 ? 0 : Math.floor( Math.log(byte) / Math.log(1024) );
  return ( byte / Math.pow(1024, i) ).toFixed(2) * 1 + ' ' + ['B', 'KB', 'MB', 'GB', 'TB'][i];
};

function percentage (total, usage) {
  return usage / total * 100
}

export const Cpu = {
  totalUsagePercent (data) {
    return data[0].usage
  }
}

export const Memory = {
  total (data) {
    return data.total * 1024
  },

  totalText (data) {
    return fileSize(this.total(data))
  },

  free (data) {
    return (data.available - data.cached - data.buffer) * 1024
  },

  freeText (data) {
    return fileSize(this.free(data))
  },

  nonCacheBuffer (data) {
    return (data.total - data.available) * 1024
  },

  nonCacheBufferText (data) {
    return fileSize(this.nonCacheBuffer(data))
  },

  usagePercent (data) {
    return percentage(this.total(data), this.nonCacheBuffer(data))
  },

  swapTotalText (data) {
    return fileSize(data.swap_total)
  },

  swapUsage (data) {
    return data.swap_total - data.swap_free
  },

  swapUsageText (data) {
    return fileSize(this.swapUsage(data))
  }
}

export const Disk = {
  totalSize (data) {
    return data.reduce((acc, disk) => acc + disk.total, 0) * 1024
  },

  totalSizeText (data) {
    return fileSize(this.totalSize(data))
  },

  totalUsage (data) {
    return data.reduce((acc, disk) => acc + disk.used, 0) * 1024
  },

  totalUsageText (data) {
    return fileSize(this.totalUsage(data))
  },

  totalUsagePercent (data) {
    return percentage(this.totalSize(data), this.totalUsage(data))
  }
}

export const Network = {
  read (data) {
    return data.reduce((acc, iface) => acc + iface.rx_speed, 0) * 1024
  },

  write (data) {
    return data.reduce((acc, iface) => acc + iface.tx_speed, 0) * 1024
  },

  speedText(speed) {
    return fileSize(speed) + "/s"
  }
}
