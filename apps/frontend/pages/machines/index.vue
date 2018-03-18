<template>
  <div>
    <el-checkbox v-model="autoRefresh">3초마다 실시간으로 불러오기</el-checkbox>
    <el-table
      :data="tableData"
      style="width: 100%"
      :cell-style="{height: '10px', padding: '5px'}"
      :default-sort="{prop: 'name'}"
      row-key="name"
    >
      <el-table-column
        fixed
        align="center"
        header-align="center"
        :sortable="true"
        prop="name"
        label="Name"
        min-width="100px">
        <template slot-scope="scope">
          <router-link :to="'/machines/' + scope.row.name">
            {{ scope.row.name }}
          </router-link>
        </template>
      </el-table-column>
      <el-table-column
        align="center"
        header-align="center"
        prop="host"
        label="Host"
        min-width="130px"
      />
      <el-table-column
        align="center"
        header-align="center"
        :sortable="true"
        prop="status"
        label="Status"
        min-width="90px"
      />
      <el-table-column
        align="center"
        header-align="center"
        v-for="column in metricColumns"
        :prop="column.name"
        :label="capitalize(column.name)"
        :key="column.name"
        :min-width="column.width"
      />
    </el-table>
  </div>
</template>

<script>
function readableFileSize(size) {
  var i = size == 0 ? 0 : Math.floor( Math.log(size) / Math.log(1024) );
  return ( size / Math.pow(1024, i) ).toFixed(2) * 1 + ' ' + ['B', 'KB', 'MB', 'GB', 'TB'][i];
};

export default {
  data () {
    return {
      machine_list: [],
      metric_map: {},
      autoRefresh: false,
      metricColumns: [
        {name: "cpu", width: "100px"},
        {name: "memory", width: "170px"},
        {name: "disk", width: "180px"},
        {name: "network", width: "170px"}
      ],
      timer: null
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
    this.timer = setInterval(function () {
      if (this.autoRefresh) {
        this.fetchMetric()
      }
    }.bind(this), 3000)
  },

  beforeDestroy () {
    clearInterval(this.timer)
  },

  methods: {
    async fetchMetric () {
      var metric_list = await this.$axios.$get('/api/metric')
      this.metric_map = metric_list.reduce(function(acc, metric) {acc[metric.name] = metric; return acc}, {})
    },

    metricToRow (metric) {
      let row = this.metricColumns.reduce(function(map, column) {
        map[column.name] = "-"
        return map
      }, {})

      row.status = metric.status == "ok" ? "O" : "X"

      if (metric.status == "error") {
        return row
      }
      let self = this
      this.metricColumns.forEach(function({name}) {
        row[name] = self.metricToCell(name, metric.data)
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
      else if (column == "memory") {
        let total = data.total
        let nonCacheBuffer = (data.total - data.available)
        return readableFileSize(nonCacheBuffer*1024) + " / " + readableFileSize(total*1024)
      }
      else if (column == "disk") {
        let total = 0
        let used = 0
        data.forEach(function(disk) {
          total += disk.total
          used += disk.used
        })
        total = total
        used = used
        return readableFileSize(used*1024) + " / " + readableFileSize(total*1024)
      }
      else if (column == "network") {
        let rx = 0, tx = 0
        data.forEach(function(iface) {
          rx += iface.rx_speed
          tx += iface.tx_speed
        })
        return readableFileSize(rx * 1024) + "/s" + " - " + readableFileSize(tx * 1024) + "/s"
      }
    },

    capitalize (s) {
      return s[0].toUpperCase() + s.slice(1)
    }
  }
}
</script>
