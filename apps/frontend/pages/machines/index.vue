<template>
  <div>
    <p>Machines page</p>
    <input type='checkbox' id='auto-refresh' v-model='auto_refresh'>
    <label for='auto-refresh'>자동 새로고침</label>
    <table id='machines-table'>
      <thead>
        <tr>
          <th>name</th>
          <th>host</th>
          <th>status</th>
          <th>CPU</th>
        </tr>
      </thead>
      <tbody>
        <tr is='machine-row'
          v-for='machine in machine_list'
          :info='machine'
          :metric='metric_map[machine.name]'
          :key='machine.name'
        ></tr>
      </tbody>
    </table>
  </div>
</template>

<script>
import MachineRow from '~/components/MachineRow.vue'

export default {
  data () {
    return {
      machine_list: [],
      metric_map: {},
      auto_refresh: false
    }
  },
  async asyncData ({ app }) {
    let machine_list, metric_list
    [machine_list, metric_list] = await Promise.all([
      app.$axios.$get('/api/machines'),
      app.$axios.$get('/api/metric')
    ])
    return {
      machine_list: machine_list.sort(function(a,b) {
        if (a.name > b.name)return 1
        else if (a.name < b.name)return -1
        else return 0
      }),
      metric_map: metric_list.reduce(function(acc, metric) {
        acc[metric.name] = metric;
        return acc
      }, {})
    }
  },
  created () {
    this.fetchMetric()
    setInterval(function () {
      if (this.auto_refresh){
        this.fetchMetric();
      }
    }.bind(this), 3000);
  },
  methods: {
    async fetchMetric () {
      var metric_list = await this.$axios.$get('/api/metric')
      this.metric_map = metric_list.reduce(function(acc, metric) {acc[metric.name] = metric; return acc}, {})
    }
  },
  components: {
    MachineRow
  }
}
</script>

<style>
table {
  border-collapse: collapse;
}

table, th, td {
  border: 1px solid black;
}
</style>
