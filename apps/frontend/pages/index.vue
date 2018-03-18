<template>
  <div>
    <el-col :xs="24" :sm="12" :md="12" :lg="12">
      <el-card id="overview" body-style="display: -webkit-flex; display: flex; flex-wrap: wrap; padding: 0px;">
        <template slot="header">
          <h2>Overview</h2>
        </template>
        <overview-item
          v-for="overview in overviews"
          :key="overview.title"
          :title="overview.title"
          :value="overview.value"
        />
      </el-card>
    </el-col>
  </div>
</template>

<script>
import OverviewItem from '~/components/OverviewItem.vue'

export default {
  data () {
    return {
      machines: []
    }
  },

  async asyncData ({ app }) {
    let machines, metrics
    [machines, metrics] = await Promise.all([
      app.$axios.$get('/api/machines'),
      app.$axios.$get('/api/metric')
    ])

    return {
      machines,
      metrics
    }
  },

  computed: {
    overviews () {
      let aliveMachines = this.metrics.filter((machine) => machine.status === "ok").length
      return [
        {title: "Total Machines", value: this.machines.length},
        {title: "Alive Machines", value: aliveMachines},

      ]
    }
  },

  components: {
    OverviewItem
  }
}
</script>
