import ChartLive from 'chart.js/auto'
import 'chartjs-adapter-luxon'
import ChartStreaming from 'chartjs-plugin-streaming'
ChartLive.register(ChartStreaming)

// A wrapper of Chart.js that configures the realtime line chart.
export default class {
    constructor(ctx) {
        this.colors = [
            'rgba(255, 99, 132, 1)',
            'rgba(54, 162, 235, 1)',
            'rgba(255, 206, 86, 1)',
            'rgba(75, 192, 192, 1)',
            'rgba(153, 102, 255, 1)',
            'rgba(255, 159, 64, 1)'
        ]

        const config = {
            type: 'line',
            data: { datasets: [] },
            options: {
                datasets: {
                    // https://www.chartjs.org/docs/3.6.0/charts/line.html#dataset-properties
                    line: {
                        // 線グラフに丸みを帯びさせる。
                        tension: 0.3
                    }
                },
                plugins: {
                    // https://nagix.github.io/chartjs-plugin-streaming/2.0.0/guide/options.html
                    streaming: {
                        // 表示するX軸の幅をミリ秒で指定。
                        duration: 5 * 60 * 1000,
                        // Chart.jsに点をプロットする猶予を与える。
                        delay: 50
                    }
                },
                scales: {
                    x: {
                        // chartjs-plugin-streamingプラグインの機能をつかうための型。
                        type: 'realtime'
                    },
                    y: {
                        // あらかじめY軸の範囲をChart.jsに教えてあげると、グラフの更新がスムーズです。
                        suggestedMin: 50,
                        suggestedMax: 200
                    }
                }
            }
        }

        this.chart = new ChartLive(ctx, config)
    }

    addPoint(label, event) {
        const dataset = this._findDataset(label) || this._createDataset(label)
        dataset.data.push({ x: new Date(event.tstamp / 1000000), y: event.val })
        this.chart.update()
    }

    destroy() {
        this.chart.destroy()
    }

    _findDataset(label) {
        return this.chart.data.datasets.find((dataset) => dataset.label === label)
    }

    _createDataset(label) {
        const newDataset = { label, data: [], borderColor: this.colors.pop() }
        this.chart.data.datasets.push(newDataset)
        return newDataset
    }
}

//loading chartjs
const Chart = require("chart.js/auto");

//A Canvas dom element with ID "lineChart" is where our chart will display
var lineChart = document.getElementById("lineChart");

var ctx = lineChart && lineChart.getContext("2d");

var chart_data = [1, 2, 3, 4];
var chart_labels = [1, 2, 3, 4];

if (ctx) {
    var myChart = new Chart(ctx, {
        type: "line",
        data: {
            //we make sure of the following variable to available in the template that uses this JS file and it act as X-Axis
            labels: chart_labels,
            datasets: [
                {
                    label: "Coffee extraction",

                    // Adjust the colors and Background here if you need
                    backgroundColor: "rgba(155, 89, 182,0.2)",
                    borderColor: "rgba(142, 68, 173,1.0)",
                    pointBackgroundColor: "rgba(142, 68, 173,1.0)",

                    //we make sure of the following variable to available in the template that uses this JS
                    data: chart_data,
                },
            ],
        },
        options: {
            responsive: true,
            aspectRatio: 7,
            scales: {
                y: {
                    max: 10
                },
                x: {
                    max: 600
                }
            },
        },
    });
}