# qgis models
[sql version](models/distDirFromPointSQL.model3)

[accompanying model to calculate cbd/city center](models/createCBD.model3)

### sql distance/direction model as python script
```python
from qgis.core import QgsProcessing
from qgis.core import QgsProcessingAlgorithm
from qgis.core import QgsProcessingMultiStepFeedback
from qgis.core import QgsProcessingParameterFeatureSource
from qgis.core import QgsProcessingParameterString
from qgis.core import QgsProcessingParameterFeatureSink
import processing


class DistanceAndDirectionFromPointSql(QgsProcessingAlgorithm):

    def initAlgorithm(self, config=None):
        self.addParameter(QgsProcessingParameterFeatureSource('citycenter', 'City Center', types=[QgsProcessing.TypeVector], defaultValue=None))
        self.addParameter(QgsProcessingParameterString('fieldnameprefix', 'Field Name Prefix', multiLine=False, defaultValue='cbd'))
        self.addParameter(QgsProcessingParameterFeatureSource('inputfeatures2', 'Input Features ', types=[QgsProcessing.TypeVectorPolygon], defaultValue=None))
        self.addParameter(QgsProcessingParameterFeatureSink('DirectionDistanceOutput', 'Direction Distance Output', type=QgsProcessing.TypeVectorAnyGeometry, createByDefault=True, defaultValue=None))

    def processAlgorithm(self, parameters, context, model_feedback):
        # Use a multi-step feedback, so that individual child algorithm progress reports are adjusted for the
        # overall progress through the model
        feedback = QgsProcessingMultiStepFeedback(4, model_feedback)
        results = {}
        outputs = {}

        # Mean coordinate(s)
        alg_params = {
            'INPUT': parameters['citycenter'],
            'UID': None,
            'WEIGHT': None,
            'OUTPUT': QgsProcessing.TEMPORARY_OUTPUT
        }
        outputs['MeanCoordinates'] = processing.run('native:meancoordinates', alg_params, context=context, feedback=feedback, is_child_algorithm=True)

        feedback.setCurrentStep(1)
        if feedback.isCanceled():
            return {}

        # Execute SQL (distance)
        alg_params = {
            'INPUT_DATASOURCES': [parameters['citycenter'],parameters['inputfeatures2']],
            'INPUT_GEOMETRY_CRS': None,
            'INPUT_GEOMETRY_FIELD': '',
            'INPUT_GEOMETRY_TYPE': None,
            'INPUT_QUERY': 'select *, distance(centroid(transform((geometry),4326)) ,  transform((select geometry from input1),4326), true) as [%concat(@fieldnameprefix , \'Dist\')%]\nfrom input2',
            'INPUT_UID_FIELD': '',
            'OUTPUT': QgsProcessing.TEMPORARY_OUTPUT
        }
        outputs['ExecuteSqlDistance'] = processing.run('qgis:executesql', alg_params, context=context, feedback=feedback, is_child_algorithm=True)

        feedback.setCurrentStep(2)
        if feedback.isCanceled():
            return {}

        # Field calculator (direction)
        alg_params = {
            'FIELD_LENGTH': 10,
            'FIELD_NAME': QgsExpression('concat( @fieldnameprefix , 'Dir')').evaluate(),
            'FIELD_PRECISION': 3,
            'FIELD_TYPE': 0,
            'FORMULA': 'degrees(azimuth(  \r\n\r\ntransform( make_point(  @Mean_coordinate_s__OUTPUT_maxx ,  @Mean_coordinate_s__OUTPUT_maxy ) ,  layer_property( @citycenter, \'crs\') , \'EPSG:54004\') , \r\ntransform(centroid($geometry) , layer_property (@inputfeatures2, \'crs\') , \'EPSG:54004\')))',
            'INPUT': outputs['ExecuteSqlDistance']['OUTPUT'],
            'NEW_FIELD': True,
            'OUTPUT': QgsProcessing.TEMPORARY_OUTPUT
        }
        outputs['FieldCalculatorDirection'] = processing.run('qgis:fieldcalculator', alg_params, context=context, feedback=feedback, is_child_algorithm=True)

        feedback.setCurrentStep(3)
        if feedback.isCanceled():
            return {}

        # Field calculator(cardinal and ordinal direction)
        alg_params = {
            'FIELD_LENGTH': 10,
            'FIELD_NAME': QgsExpression('concat( @fieldnameprefix , 'CardOrd')').evaluate(),
            'FIELD_PRECISION': 3,
            'FIELD_TYPE': 2,
            'FORMULA': 'CASE\r\nWHEN attribute(concat(@fieldnameprefix, \'Dir\'))<=22.5 or attribute(concat(@fieldnameprefix, \'Dir\'))>=337.5 THEN \'N\'\r\nWHEN attribute(concat(@fieldnameprefix, \'Dir\'))<=67.5 and attribute(concat(@fieldnameprefix, \'Dir\'))>=22.5 THEN \'NE\'\r\nWHEN attribute(concat(@fieldnameprefix, \'Dir\'))<=(135-22.5) and attribute(concat(@fieldnameprefix, \'Dir\'))>=(45+22.5) THEN \'E\'\r\nWHEN attribute(concat(@fieldnameprefix, \'Dir\'))<=157.5 and attribute(concat(@fieldnameprefix, \'Dir\'))>=112.5THEN \'SE\'\r\nWHEN attribute(concat(@fieldnameprefix, \'Dir\'))<=292.5 and attribute(concat(@fieldnameprefix, \'Dir\'))>=247.5 THEN \'W\'\r\nWHEN attribute(concat(@fieldnameprefix, \'Dir\'))<=247.5 and attribute(concat(@fieldnameprefix, \'Dir\'))>=202.5 THEN \'SW\'\r\nWHEN attribute(concat(@fieldnameprefix, \'Dir\'))<=337.5 and attribute(concat(@fieldnameprefix, \'Dir\'))>=292.5 THEN \'NW\'\r\nWHEN attribute(concat(@fieldnameprefix, \'Dir\'))<=202.5and attribute(concat(@fieldnameprefix, \'Dir\'))>=157.5 THEN \'S\'\r\nEND\r\n\r\n',
            'INPUT': outputs['FieldCalculatorDirection']['OUTPUT'],
            'NEW_FIELD': True,
            'OUTPUT': parameters['DirectionDistanceOutput']
        }
        outputs['FieldCalculatorcardinalAndOrdinalDirection'] = processing.run('qgis:fieldcalculator', alg_params, context=context, feedback=feedback, is_child_algorithm=True)
        results['DirectionDistanceOutput'] = outputs['FieldCalculatorcardinalAndOrdinalDirection']['OUTPUT']
        return results

    def name(self):
        return 'Distance and Direction from Point (SQL)'

    def displayName(self):
        return 'Distance and Direction from Point (SQL)'

    def group(self):
        return 'Middlebury'

    def groupId(self):
        return 'Middlebury'

    def shortHelpString(self):
        return """<html><body><h2>Algorithm description</h2>
<p>This model calculates distance and direction from a given point.</p>
<h2>Input parameters</h2>
<h3>City Center</h3>
<p>The city center is the point from which distance and direction will be calculated. An existing point should be used as the city center. The output from Create CBD/City Center can be used here. </p>
<h3>Field Name Prefix</h3>
<p>This prefix will be added to the new distance and direction fields.</p>
<h3>Input Features </h3>
<p>Direction and distance from the city center will be calculated for this layer. </p>
<h3>Direction Distance Output</h3>
<p>This layer has new fields for direction in degrees, distance in meters, and cardinal and ordinal directions  </p>
<h2>Outputs</h2>
<h3>Direction Distance Output</h3>
<p>This layer has new fields for direction in degrees, distance in meters, and cardinal and ordinal directions  </p>
<br></body></html>"""

    def helpUrl(self):
        return 'kufreu.github.io'

    def createInstance(self):
        return DistanceAndDirectionFromPointSql()
```
[python script](models/disDirFromPointSQL.py)
