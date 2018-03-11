<template>
  <div>
    <p>Machines page</p>
    <input type='checkbox' id='auto-refresh' v-model='auto_refresh'>
    <label for='auto-refresh'>자동 새로고침</label>
    <el-table
      :data="tableData"
      style="width: 100%"
      :cell-style="{height: '10px', padding: '5px'}"
      :default-sort="{prop: 'name'}"
      row-key="name"
    >
      <el-table-column
        fixed
        :sortable="true"
        prop="name"
        label="Name"
      />
      <el-table-column
        prop="host"
        label="Host"
      />
      <el-table-column
        :sortable="true"
        prop="status"
        label="Status"
      />
      <el-table-column
        v-for="column in metricColumns"
        :prop="column"
        :label="capitalize(column)"
        :key="column"
      />
    </el-table>
  </div>
</template>

<script>
export default {
  data () {
    return {
      machine_list: [],
      metric_map: {},
      auto_refresh: false,
      metricColumns: [
        "cpu"
      ]
    }
  },

  computed: {
    tableData () {
      return this.machine_list.map((machine) => Object.assign(machine, this.metricToRow(this.metric_map[machine.name])))
    }
  },

  async asyncData ({ app }) {
    let machine_list, metric_list
    [machine_list, metric_list] = await Promise.all([
      app.$axios.$get('/api/machines'),
      app.$axios.$get('/api/metric')
    ])
    return {
      machine_list,
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
    },

    metricToRow (metric) {
      let row = this.metricColumns.reduce(function(map, column) {
        map[column] = "-"
        return map
      }, {})

      row.status = metric.status == "ok" ? "O" : "X"

      if (metric.status == "error") {
        return row
      }
      let self = this
      this.metricColumns.forEach(function(column) {
        row[column] = self.metricToCell(column, metric.data)
      })
      return row
    },

    metricToCell (column, metric) {
      if (metric[column].status == "error") {
        return "-"
      }

      let data = metric[column].data

      if (column == "cpu") {
        return data[0].usage.toFixed(2) + "%"
      }
    },

    capitalize (s) {
      return s[0].toUpperCase() + s.slice(1)
    }
  }
}
</script>
