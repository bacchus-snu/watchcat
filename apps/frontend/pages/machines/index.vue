<template>
  <div>
    <auto-refresh-checkbox/>
    <el-table
      :data="tableData"
      style="width: 100%"
      :cell-style="{height: '42px', padding: '3px'}"
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
        :sortable="column.isGroup ? false : true"
        :sort-method="(a,b) => sortColumn(a,b,column.name)">
        <el-table-column
          v-if="column.isGroup"
          align="center"
          header-align="center"
          v-for="subcolumn in column.subcolumns"
          :prop="column.name + ' ' + subcolumn.name"
          :label="capitalize(subcolumn.name)"
          :key="column.name + ' ' + subcolumn.name"
          :min-width="subcolumn.width"
          :sortable="true"
          :sort-method="(a,b) => sortColumn(a,b,column.name + ' ' + subcolumn.name)">
          <template slot-scope="scope">
            <div class="cell-brief">{{ scope.row[column.name + ' ' + subcolumn.name].brief }}</div>
            <div class="cell-detail" v-if="scope.row[column.name + ' ' + subcolumn.name].detail">
              {{ scope.row[column.name + ' ' + subcolumn.name].detail }}
            </div>
          </template>
        </el-table-column>
        <template slot-scope="scope" v-if="!column.isGroup">
          <div class="cell-brief">{{ scope.row[column.name].brief }}</div>
          <div v-if="scope.row[column.name].detail" class="cell-detail">
            {{ scope.row[column.name].detail }}
          </div>
        </template>
      </el-table-column>
    </el-table>
  </div>
</template>

<script>
import AutoRefreshCheckbox from '~/components/AutoRefreshCheckbox.vue'
import {Cpu, Memory, Disk, Network} from '~/utils/metricCalc.js'

export default {
  data () {
    return {
      machine_list: [],
      metric_map: {},
      metricColumns: [
        {name: "cpu", width: "100px"},
        {name: "memory", width: "160px"},
        {name: "disk", width: "160px"},
        {
          name: "network",
          isGroup: true,
          subcolumns: [
            {name: "read", width: "110px"},
            {name: "write", width: "110px"}
          ]
        }
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
      if (this.$store.state.autoRefresh) {
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
        if (column.isGroup) {
          column.subcolumns.forEach(function(subcolumn) {
            map[column.name + ' ' + subcolumn.name] = {value: -1, brief: "-"}
          })
        } else {
          map[column.name] = {value: -1, brief: "-"}
        }
        return map
      }, {})

      row.status = metric.status === "ok" ? "O" : "X"

      if (metric.status === "error") {
        return row
      }
      let self = this
      this.metricColumns.forEach(function(column) {
        if (column.isGroup) {
          column.subcolumns.forEach(function(subcolumn) {
            let name = column.name + ' ' + subcolumn.name
            row[name] = self.metricToCell(name, metric.data)
          })
        } else {
          row[column.name] = self.metricToCell(column.name, metric.data)
        }
      })
      return row
    },

    metricToCell (column, metric) {
      let columnGroup = column.split(" ")[0]
      if (metric[columnGroup].status === "error") {
        return {value: -1, brief: "-"}
      }

      let data = metric[columnGroup].data

      if (column === "cpu") {
        let percent = Cpu.totalUsagePercent(data)
        return {
          value: percent,
          brief: percent.toFixed(2) + " %"
        }
      }
      else if (column === "memory") {
        let percent = Memory.usagePercent(data)
        return {
          value: percent,
          brief: percent.toFixed(2) + " %",
          detail: Memory.nonCacheBufferText(data) + " / " + Memory.totalText(data)
        }
      }
      else if (column === "disk") {
        let percent = Disk.totalUsagePercent(data)
        return {
          value: percent,
          brief: percent.toFixed(2) + " %",
          detail: Disk.totalUsageText(data) + " / " + Disk.totalSizeText(data)
        }
      }
      else if (column === "network read") {
        let speed = Network.read(data)
        return {
          value: speed,
          brief: Network.speedText(speed)
        }
      }
      else if (column === "network write") {
        let speed = Network.write(data)
        return {
          value: speed,
          brief: Network.speedText(speed)
        }
      }
    },

    sortColumn(a, b, column) {
      let aVal = a[column].value
      let bVal = b[column].value

      return aVal === bVal ? 0 : aVal < bVal ? 1 : -1
    },

    capitalize (s) {
      return s[0].toUpperCase() + s.slice(1)
    }
  },

  components: {
    AutoRefreshCheckbox
  }
}
</script>

<style>
.cell-brief {
  line-height: 20px;
}

.cell-detail {
  font-size: 12px;
  color: rgb(150,150,150);
  line-height: 15px;
}
</style>
