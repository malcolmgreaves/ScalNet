/*
 *
 *  * Copyright 2016 Skymind,Inc.
 *  *
 *  *    Licensed under the Apache License, Version 2.0 (the "License");
 *  *    you may not use this file except in compliance with the License.
 *  *    You may obtain a copy of the License at
 *  *
 *  *        http://www.apache.org/licenses/LICENSE-2.0
 *  *
 *  *    Unless required by applicable law or agreed to in writing, software
 *  *    distributed under the License is distributed on an "AS IS" BASIS,
 *  *    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  *    See the License for the specific language governing permissions and
 *  *    limitations under the License.
 *
 */

package org.deeplearning4j.scalnet.layers.reshaping

import org.deeplearning4j.nn.conf.InputPreProcessor
import org.deeplearning4j.nn.conf.inputs.InputType
import org.deeplearning4j.nn.conf.preprocessor.BaseInputPreProcessor
import org.deeplearning4j.scalnet.layers.Preprocessor
import org.nd4j.linalg.api.ndarray.INDArray


/**
  * Generic reshaping layer.
  *
  * @author David Kale
  */
class Reshape(
    newOutputShape: List[Int],
    oldInputShape: List[Int] = List())
  extends Preprocessor {
  override val inputShape: List[Int] = oldInputShape
  override val outputShape: List[Int] = newOutputShape
  override val name = "Reshape"

  override def reshapeInput(newIn: List[Int]): Reshape = {
    new Reshape(newOutputShape, newIn)
  }

  private class ReshapePreProcessor(private var fromShape: Option[Array[Int]],
                                    private val toShape: Array[Int], private val dynamic: Boolean = true)
    extends BaseInputPreProcessor with Cloneable {

    override def preProcess(input: INDArray, miniBatchSize: Int): INDArray = {
      if (dynamic && fromShape != None) fromShape.get(0) = input.shape()(0)
      if (input.shape().length == toShape.length) input else input.reshape(toShape: _*)
    }

    override def backprop(output: INDArray, miniBatchSize: Int): INDArray = {
      if (fromShape == None || outputShape.length == fromShape.get.length) {
        output
      } else if (output.length() != fromShape.get.product) {
        throw new IllegalStateException("Illegal shape")
      } else {
        output.reshape(fromShape.get: _*)
      }
    }

    override def getOutputType(inputType: InputType): InputType = {
      toShape.length match {
        case 2 | 3 => InputType.feedForward(toShape(1))
        case 4 => InputType.convolutional(toShape(3), toShape(2), toShape(1))
        case _ => throw new IllegalStateException("Output shape not understood.")
      }
    }

  }

  private object ReshapePreProcessor{
    def apply(toShape: Int*): ReshapePreProcessor = new ReshapePreProcessor(None, toShape.toArray, true)
  }

  override def compile: InputPreProcessor = {
    if (PartialFunction.cond(inputShape){ case Nil => true; case 0::Nil => true}) {
      throw new IllegalArgumentException("Input shape must be nonempty and nonzero.")
    }
    if (inputShape.product != outputShape.product) {
      throw new IllegalArgumentException("Overall input shape must equal overall output shape.")
    }
    new ReshapePreProcessor(Some(inputShape.toArray), outputShape.toArray)
  }
}

object Reshape {
  def apply(newOutputShape: List[Int], oldInputShape: List[Int] = List()): Reshape = {
    new Reshape(newOutputShape, oldInputShape)
  }
}