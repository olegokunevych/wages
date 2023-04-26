import RealtimeLineChart from '../linechart'

export default {
    mounted() {
        this.chart = new RealtimeLineChart(this.el)

        this.handleEvent('new-point', ({ label, value }) => {
            this.chart.addPoint(label, value)
        })
    },
    destroyed() {
        this.chart.destroy()
    }
}