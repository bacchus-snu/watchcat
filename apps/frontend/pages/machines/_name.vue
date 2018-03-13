<template>
  <div>
    <el-card id="basic-info-card" body-style="padding: 10px">
      <el-row :gutter="40">
        <el-col :span="8" class="info">
          <i class="el-icon-info"/>
          <span> Name - {{ machine.name }}</span>
        </el-col>
        <el-col :span="8" class="info">
          <i class="el-icon-info"/>
          <span> Host - {{ machine.host }}</span>
        </el-col>
        <el-col :span="8" class="info">
          <i :class='metric.status === "ok" ? "el-icon-success" : "el-icon-error"'/>
          <span> Status - {{ metric.status }}</span>
        </el-col>
      </el-row>
    </el-card>
    <template v-if="metric.status === 'ok'">
      <el-row :gutter="20">
        <el-col :span="6">
          <cpu-card :metric="metric.data.cpu"/>
        </el-col>
        <el-col :span="6">
          <memory-card :metric="metric.data.memory"/>
        </el-col>
      </el-row>
    </template>
    <template v-else>
      <p>Metric is not available</p>
    </template>
  </div>
</template>

<script>
import CpuCard from '~/components/CpuCard.vue'
import MemoryCard from '~/components/MemoryCard.vue'

export default {
  data () {
    return {
      machine: null,
      metric: null
    }
  },

  async asyncData ({ app, params, error }) {
    try {
      let machine, metric
      [machine, metric] = await Promise.all([
        app.$axios.$get('/api/machines/' + params.name),
        app.$axios.$get('/api/metric/' + params.name)
      ])

      return {
        machine,
        metric
      }
    }
    catch (err) {
      error({ statusCode: 404, message: 'Machine not found'})
    }
  },

  components: {
    CpuCard,
    MemoryCard
  }
}
</script>

<style>
.el-icon-success {
  color: green;
}

.info {
  text-align: center;
  font-size: 16px;
}

#basic-info-card {
  margin-bottom: 10px;
}

.card-body {
  display: -webkit-flex;
  display: flex;
  -webkit-flex-direction: column;
  flex-direction: column;
}

.line {
  border-top: 1px solid rgb(230, 230, 230);
}

.el-progress {
  margin: 0px auto 10px auto;
}
</style>
