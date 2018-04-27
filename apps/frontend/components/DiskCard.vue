<template>
  <el-card>
    <h2 slot="header">Disk</h2>
    <div class="card-body">
      <template v-if="disk.ok">

      </template>
      <template v-else>
        <p>{{ disk.reason }}</p>
      </template>
    </div>
  </el-card>
</template>

<script>
export default {
  props: ["metric"],

  computed: {
    disk () {
      let diskInfo = this.metric
      let ret = {}
      ret.ok = diskInfo.status === "ok"
      if (ret.ok) {
        // do something...
      } else {
        ret.reason = diskInfo.reason
      }

      return ret
    }
  }
}
</script>
