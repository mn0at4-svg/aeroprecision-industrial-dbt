<script>
    import '@evidence-dev/tailwind/fonts.css';
    import '../app.css';
    import { EvidenceDefaultLayout } from '@evidence-dev/core-components';

    export let data;
</script>

<EvidenceDefaultLayout
    {data}
    title="AeroPrecision Industrial"
    homePageName="CFO Dashboard"
    fullWidth=false
    maxWidth=1440
    hideSidebar=true
    hideTOC=true
    hideBreadcrumbs=true
    neverShowQueries=true
    builtWithEvidence=false
>
    <slot slot="content" />
</EvidenceDefaultLayout>