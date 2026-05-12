/**********************************************************************************
 * @filename      : zChartjsTest.js
 * @project-name  : LK보험중계_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2025-12-30 (화)
 * @group         :
 * @group-content :
 * @description   :
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date             author            description
 * ===================================================================
 * 1.0   2025-12-30      i2max      Create
 **********************************************************************************/
import { LightningElement } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import CHARTJS from '@salesforce/resourceUrl/chartjs';
import ANNO from '@salesforce/resourceUrl/chartjsAnnotation';

export default class zChartjsTest extends LightningElement {
    chart;
    inited = false;

    async renderedCallback() {
        if (this.inited) return;

        console.log('[ChartJS] base url =', CHARTJS);

        const chartCandidates = [
            CHARTJS + '/dist/chart.umd.min.js',
            CHARTJS + '/chart.umd.min.js'
        ];

        const annoCandidates = [
            ANNO + '/chartjs-plugin-annotation.min.js'
        ];

        const chartUrl = await this.pickFirst200(chartCandidates, 'ChartJS');
        if (!chartUrl) return;

        const annoUrl = await this.pickFirst200(annoCandidates, 'Annotation');

        try {
            const loads = [loadScript(this, chartUrl)];
            if (annoUrl) loads.push(loadScript(this, annoUrl));
            await Promise.all(loads);

            console.log('[ChartJS] load OK. window.Chart =', window.Chart);
            console.log('[Anno] globals =',
                window['chartjs-plugin-annotation'],
                window.ChartAnnotation
            );

            if (!window.Chart) {
                console.error('Chart 전역이 없습니다. UMD 파일이 아닌 것을 로드했을 가능성이 큽니다.');
                return;
            }
        } catch (e) {
            console.error('[loadScript FAIL]', e);
            return;
        }

        const Chart = window.Chart;
        const anno = window['chartjs-plugin-annotation'] || window.ChartAnnotation;
        if (anno?.default) Chart.register(anno.default);
        else if (anno) Chart.register(anno);

        const canvas = this.template.querySelector('canvas');
        if (!canvas) {
            console.error('canvas를 찾지 못했습니다. template에 canvas가 있는지 확인하세요.');
            return;
        }

        const ctx = canvas.getContext('2d');
        this.chart = new Chart(ctx, {
            type: 'scatter',
            data: { datasets: [] },
            options: {
                animation: false,
                responsive: false,
                maintainAspectRatio: false,
                devicePixelRatio: 2,//선명도
                plugins: {
                    legend: { display: false },
                    tooltip: { enabled: false },
                    annotation: {
                        annotations: {
                            insurerSplit: { type: 'line', xMin: 40, xMax: 40, yMin: 0, yMax: 100, borderWidth: 3 },
                            cedentLabel: {
                                type: 'box', xMin: 20, xMax: 40, yMin: 60, yMax: 100, borderWidth: 0,
                                backgroundColor: 'rgba(255,191,0,0.9)',
                                label: { display: true, content: '원수사 40%', position: 'center', color: '#111', font: { size: 16, weight: '600' } },
                                clip: false
                            },
                            primary1: { type: 'box', xMin: 40, xMax: 100, yMin: 0, yMax: 20, borderWidth: 2, borderDash: [6,4],
                                borderColor: 'rgba(242, 118, 73, 1)',
                                backgroundColor: 'rgba(242, 118, 73, 0.08)',
                                label: { display: true, content: '재보험자 Primary 1: 20%', position: 'center' }, color: 'rgba(242, 118, 73, 1)', font: { size: 16, weight: '600' }
                            },
                            xol1: { type: 'box', xMin: 40, xMax: 52, yMin: 20, yMax: 60, borderWidth: 2, borderDash: [6,4],
                                borderColor: 'rgba(143, 63, 191, 1)',
                                backgroundColor: 'rgba(143, 63, 191, 0.08)',
                                label: { display: true, content: ['재보험자', 'XoL 1: 20%'], position: 'center', color: 'rgba(143, 63, 191, 1)', font: { size: 16, weight: '600' } } },
                            primary2: { type: 'box', xMin: 52, xMax: 76, yMin: 20, yMax: 60, borderWidth: 2, borderDash: [6,4],
                                borderColor: 'rgba(90, 90, 90, 1)',
                                backgroundColor: 'rgba(90, 90, 90, 0.06)',
                                label: { display: true, content: '재보험사 Primary 2: 40%', position: 'center', color: 'rgba(90, 90, 90, 1)', font: { size: 16, weight: '600' } } },
                            xol2: { type: 'box', xMin: 40, xMax: 100, yMin: 60, yMax: 100, borderWidth: 2, borderDash: [6,4],
                                borderColor: 'rgba(46, 125, 50, 1)',
                                backgroundColor: 'rgba(255, 99, 132, 0.25)',
                                label: { display: true, content: '재보험사 XoL 2: 60%', position: 'center', color: 'rgba(46, 125, 50, 1)', font: { size: 16, weight: '600' } }
                            }
                        }
                    }
                },
                scales: {
                    x: { type: 'linear', min: 0, max: 100, ticks: { stepSize: 20 } },
                    y: { type: 'linear', min: 0, max: 100, ticks: { stepSize: 20 } }
                }
            }
        });
        this.inited = true;
    }

    async pickFirst200(urls, label) {
        for (const u of urls) {
            try {
                const r = await fetch(u);
                console.log(`[${label}] try`, u, '=>', r.status);
                if (r.status === 200) return u;
            } catch (e) {
                console.log(`[${label}] try`, u, '=> fetch error', e);
            }
        }
        console.error(`[${label}] 200 응답 경로를 찾지 못했습니다. Static Resource zip 내부 경로를 확인하세요.`);
        return null;
    }

    disconnectedCallback() {
        if (this.chart) this.chart.destroy();
    }
}