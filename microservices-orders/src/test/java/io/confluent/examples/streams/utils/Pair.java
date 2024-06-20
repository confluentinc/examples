/*
 * Copyright Confluent Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package io.confluent.examples.streams.utils;

import java.io.Serializable;
import java.util.Objects;

public class Pair<X, Y> implements Serializable {

  public final X x;
  public final Y y;

  public Pair(final X x, final Y y) {
    this.x = x;
    this.y = y;
  }

  @Override
  public String toString() {
    return "(" + x + ", " + y + ")";
  }

  @Override
  public boolean equals(final Object o) {
    if (this == o) return true;
    if (o == null || getClass() != o.getClass()) return false;
    final Pair<?, ?> pair = (Pair<?, ?>) o;
    return Objects.equals(x, pair.x) &&
      Objects.equals(y, pair.y);
  }

  @Override
  public int hashCode() {
    return Objects.hash(x, y);
  }
}