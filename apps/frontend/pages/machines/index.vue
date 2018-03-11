<template>
  <div>
    <p>Machines page</p>
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
      metric_map: {}
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
