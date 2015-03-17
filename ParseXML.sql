DECLARE @NodePaths XML = '<NodePaths><NodePath>[Credit Sales &amp; Trading - Asia]</NodePath><NodePath>[zzzz]</NodePath></NodePaths>'
IF OBJECT_ID('tempdb..#NodePaths') IS NOT NULL 
    DROP TABLE #NodePaths

CREATE TABLE #NodePaths
( 
    NodePathUID INT NULL, 
    NodePath VARCHAR(2000) NULL,
    HierarchyLevel INT NULL,
    NodePathSeacrhPattern VARCHAR(2100)
)

INSERT #NodePaths (NodePathUID,NodePath)
SELECT 
    NULL AS NodePathUID,
    R.nref.value('.','VARCHAR(2000)') AS NodePath 
FROM @NodePaths.nodes('/NodePaths/NodePath') AS R(nref) 
