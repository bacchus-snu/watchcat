<template>
  <el-card>
    <h2 slot="header">Disk</h2>
    <div class="card-body">
      <template v-if="disk.ok">
        <ul class="progress-bars">
          <li class="partition" v-for="partition in disk.partitions" :key="partition.filesystem">
            <label>{{ partition.filesystem }}</label>
            <el-progress :stroke-width=14 :text-inside=true :percentage="Number(partition.used_percent.toFixed(2))"/>
            <span class="file-size">{{ partition.totalUsageText }} / {{ partition.totalSizeText }}</span>
          </li>
        </ul>
      </template>
      <template v-else>
        <p>{{ disk.reason }}</p>
      </template>
    </div>
  </el-card>
</template>

<script>
function fileSize(byte) {
  var i = byte == 0 ? 0 : Math.floor( Math.log(byte) / Math.log(1024) );
  return ( byte / Math.pow(1024, i) ).toFixed(2) * 1 + ' ' + ['B', 'KB', 'MB', 'GB', 'TB'][i];
};

export default {
  props: ["metric"],

  computed: {
    disk () {
      let diskInfo = this.metric
      let ret = {}
      ret.ok = diskInfo.status === "ok"
      if (ret.ok) {
        ret.partitions = diskInfo.data
          .map(part => Object.assign(part, {
            'totalSizeText': fileSize(part.total * 1024),
            'totalUsageText': fileSize(part.used * 1024)
          }))
          .sort((a, b) => a.filesystem > b.filesystem)
        console.log(ret.partitions)
      } else {
        ret.reason = diskInfo.reason
      }

      return ret
    }
  }
}
</script>

<style>
.file-size {
  position: relative;
  top: -10px;

}

ul.progress-bars {
  padding: 0px 0px 0px 20px;
}

li.partition {
  position: relative;
}
</style>
