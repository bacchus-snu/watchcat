import { Doughnut, mixins } from 'vue-chartjs'
const { reactiveProp } = mixins

export default {
  extends: Doughnut,
  mixins: [reactiveProp],
  props: ['diskData'],
  name: 'disk-chart',
  mounted() {
    this.renderChart(this.chartData, {})
  }
}
